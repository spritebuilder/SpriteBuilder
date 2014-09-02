#! /usr/bin/env python
import argparse
import filecmp
import glob
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
import time
import zipfile
import json

class UserError (Exception):
    pass
    
class BuildDistribution:
    def run(self):

        parser = argparse.ArgumentParser(description='Build distribution build')
        parser.add_argument('--version',required=True)
        parser.add_argument('-sku', choices=('pro','default'), default='default', help='The build sku (default:default)')
        parser.add_argument('-private_key', default=None, help='The private_key to secure the pro version. Pro version only ')
        parser.add_argument('-dcf_hash', default=None, help='The githash that dcf was taken from. Pro version only. Optional ')
        parser.add_argument('-dcf_tag', default=None, help='The git tag that dcf was taken from. Pro version only. Optional ')
        parser.add_argument('-revision', default=None, help='The git hash that SB was taken from. Optional ')
        parser.add_argument('-mode', choices=('sandboxed','non_sandboxed'), default='non_sandboxed',help='Is the app built to run in sandboxed mode (App store) or non sandboxed (direct download). (default:non_sandboxed)')
        parser.add_argument('-tests', default=True, help='Failure to successfully run the tests stops the build. Default true ')
    
        args = parser.parse_args()
    
        if args.sku == 'pro' and args.private_key == None:
            print 'Must specify private key in pro version';
            return 1

        os.chdir('../');
        
        self.rootfolder = os.getcwd()
        
        self.run_tests = args.tests
    
        version_info = {'dcf_hash' : args.dcf_hash, 'dcf_tag' : args.dcf_tag, 'revision' : args.revision}
    
        self.build_distribution(args.version, args.sku, args.mode,  version_info, args.private_key)
    

    def build_distribution(self, version,sku, mode, version_info,  private_key=None, ):

        if sku == 'pro':
            if not os.path.isfile('Generated/AndroidXcodePlugin.zip'):
                raise Exception('Failed to find Generated/AndroidXcodePlugin.zip. Pro version requres this file');

            if private_key == None:
                raise Exception('Failed to find private_key. Pro version requires this command line argument.')
    

        self.clean_build_folders()
    
        if sku=='pro':
            product_name = 'SpriteBuilder Pro'
        else:
            product_name = 'SpriteBuilder'
        
        self.create_all_generated_files(version, sku, version_info)

    
        if self.run_tests == True: 
            self.test_project()
            
            
        self.compile_project(version, product_name, mode, private_key)
        self.zip_archive(product_name,version)

    def test_project(self):

        print "=== TESTING PROJECT ==="
        os.chdir('SpriteBuilder/');
    
        subprocess.check_call('/usr/bin/xcodebuild -alltargets clean', shell=True)
     
        try:
            subprocess.check_call('/usr/bin/xcodebuild -target "SpriteBuilder Tests" -configuration Testing -scheme SpriteBuilder test', shell=True)
        except Exception,e:
            print ("TESTS FAILED: %s" % e)
            print "Tests failed. If you'd like to ignore tests, build with '-tests false'" 
            sys.exit(1)
            
        os.chdir('../');


    def compile_project(self, version,product_name, mode, private_key):
        # Clean and build CocosBuilder
        print "=== CLEANING PROJECT ==="

        os.chdir('SpriteBuilder/');
        subprocess.check_call('/usr/bin/xcodebuild -alltargets clean', shell=True)
    
        if mode == 'sandboxed':
            sandboxed_mode_define = 'SB_SANDBOXED'
        else:
            sandboxed_mode_define = 'SB_NOT_SANDBOXED'
   
        print "=== BUILDING SPRITEBUILDER === (please be patient)"
        build_command = '/usr/bin/xcodebuild \
            -target SpriteBuilder \
            -configuration Release \
            -xcconfig \"{xcconfig}.xcconfig\" \
            SBPRO_PRIVATE_KEY=\"{private_key}\" \
            SB_SANDBOXED_MODE={sandboxed_mode_define}\
            SB_VERSION={version}\
            build'.format(xcconfig=product_name, private_key=private_key, sandboxed_mode_define=sandboxed_mode_define, version=version)

        print build_command
        subprocess.check_call(build_command.format(xcconfig=product_name, private_key=private_key, sandboxed_mode_define=sandboxed_mode_define, version=version), shell=True)

        os.chdir('../');

    def zip_archive(self, product_name,version):

        # Create archives
        print "=== ZIPPING UP FILES ==="

        if not os.path.exists('build'):
            os.makedirs('build')

        shutil.copytree('SpriteBuilder/build/Release/{product_name}.app'.format(product_name=product_name),
            'build/{product_name}.app'.format(product_name=product_name))

        shutil.copytree('SpriteBuilder/build/Release/{product_name}.app.dSYM'.format(product_name=product_name),
            'build/{product_name}.app.dSYM'.format(product_name=product_name))

        os.chdir('build/');
    
        #Zip app.
        zip_command = 'zip -q -r "{product_name}-{version}.zip" "{product_name}.app"'.format(product_name=product_name,version=version)
        subprocess.check_call(zip_command, shell=True)

    
        zip_command = 'zip -q -r "{product_name}.app.dSYM.zip" "{product_name}.app.dSYM"'.format(product_name=product_name)
        subprocess.check_call(zip_command, shell=True)


    def clean_build_folders(self):
        shutil.rmtree('build',True)
        shutil.rmtree('SpriteBuilder/build/',True)    

    def create_all_generated_files(self, version, sku, version_info):
    
        #create generated folder.
        if not os.path.exists('Generated'):
            os.makedirs('Generated')
        
        #create version.txt
        version_info['version'] = version
        version_info['sku'] = sku
    
    
        for i, j in version_info.items():       # use iteritems in py2k
            if j == None:
                version_info[i] = 'undefined'
            
        if version_info['revision'] == 'undefined':
            p = subprocess.Popen(['/usr/bin/git', 'rev-parse' ,'--short=10' ,'HEAD'],stdout=subprocess.PIPE)
            out, err = p.communicate()
            if err == None:
                out = out.strip()
                version_info['revision'] = out
        
        json.dump(version_info, open("Generated/Version.txt",'w'),sort_keys=True, indent=4)
    
        #Copy cocos version file.
        shutil.copyfile('SpriteBuilder/libs/cocos2d-iphone/VERSION','Generated/cocos2d_version.txt')

        self.generate_template_project('PROJECTNAME',sku_folder=sku)
        self.generate_template_project('SPRITEKITPROJECTNAME',sku_folder='')    


    def generate_template_project(self, project_name,sku_folder):
        #create generated folder.

    
        if not os.path.exists('Generated'):
            os.makedirs('Generated')
        
        os.chdir('{rootfolder}/Support/{sku_folder}/{project_name}.spritebuilder/'.format(project_name=project_name,rootfolder=self.rootfolder,sku_folder=sku_folder))


        # Generate template project
        print 'Generating:', project_name

        user_data = '{project_name}.xcodeproj/xcuserdata/'.format(project_name=project_name)
        if os.path.exists(user_data):
            shutil.rmtree(user_data)


        user_data = '{project_name}.xcodeproj/project.xcworkspace/xcuserdata/'.format(project_name=project_name)
        if os.path.exists(user_data):
            shutil.rmtree(user_data)

        project_zip_filename =  '{rootfolder}/Generated/{project_name}.zip'.format(project_name=project_name,rootfolder=self.rootfolder);

        if os.path.exists(project_zip_filename):
            os.remove(project_zip_filename)


    
        zip_project_command = 'zip -q -r \"{rootfolder}/Generated/{project_name}.zip\" .* -x "../*" "*.git*" "*/tests/*" "*.DS_Store"'.format(project_name=project_name,rootfolder=self.rootfolder)
        subprocess.check_call(zip_project_command, shell=True)
        shutil.copy('{rootfolder}/Support/default_projects.gitignore'.format(rootfolder=self.rootfolder),'./.gitignore')
        zip_project_command = "zip -q \"{rootfolder}/Generated/{project_name}.zip\" .gitignore".format(project_name=project_name,rootfolder=self.rootfolder)
        subprocess.check_call(zip_project_command, shell=True)
        os.remove('.gitignore')

        os.chdir(self.rootfolder)    

try:
    if __name__ == '__main__':
        build_distribution = BuildDistribution()
        sys.exit(build_distribution.run())
except UserError, e:
    print ("FATAL ERROR: %s" % e)
    sys.exit(1)
