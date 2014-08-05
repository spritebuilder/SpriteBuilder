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

BUNDLE_VERSION = 3

class UserError (Exception):
    pass

def main():
    try:
        parser = argparse.ArgumentParser(description='install an xcode plugin bundle')
        parser.add_argument('action', choices=('clean','install','validate'), help='the action to perform')
        parser.add_argument('file', help='the file to be used for package or install')
        args = parser.parse_args()
		
        if args.action == "clean":
            clean_plugin()
        elif args.action == "validate":
            validate_bundle(args.file)
        elif args.action == "install":
            install_plugin(args.file)
    except UserError, e:
        print ("FATAL ERROR: %s" % e)
        return 1

def get_component_roots(include_legacy=False):
    xcshared_dir="~/Library/Application Support/Developer/Shared/Xcode"
    library_dir="~/Library"
    user_xcode_dir="~/Library/Developer/Xcode"
	
    components = [
				  (xcshared_dir, "Platforms/Android.platform", 'CURRENT'),
				  (xcshared_dir, "PlatformPlugIns/IDEAndroidSupportCore.ideplugin", 'CURRENT'),
				  (xcshared_dir, "Plug-ins/APPPlatformBuildSystem.xcplugin", 'CURRENT'),
				  (xcshared_dir, "Plug-ins/IDEAndroidSupportCore.xcplugin", 'LEGACY'),
				  (xcshared_dir, "Plug-ins/IDEJavaSupportCore.xcplugin", 'CURRENT'),
				  (xcshared_dir, "Plug-ins/LinkageDependencies.xcplugin", 'CURRENT'),
				  (xcshared_dir, "Toolchains/Android.xctoolchain", 'CURRENT'),
				  (library_dir, "Frameworks/XCPluginKit.framework", 'CURRENT'),
				  (user_xcode_dir, "Templates/Project Templates/Java", 'CURRENT'),
				  (user_xcode_dir, "Templates/Project Templates/Framework & Library", 'CURRENT'),
				  ]
    return [(c, os.path.expanduser(os.path.join(path, c))) for path, c, type in components if include_legacy or type != 'LEGACY']


def get_defaults(include_legacy=False):
    xcshared_dir = os.path.expanduser("~/Library/Application Support/Developer/Shared/Xcode")
	
    defaults = [
				('com.apple.dt.Xcode', 'DVTExtraPlugInPaths', os.path.join(xcshared_dir, 'PlatformPlugIns'), 'CURRENT'),
				('com.apple.dt.Xcode', 'DVTExtraPlatformFolders', os.path.join(xcshared_dir, 'Platforms'), 'CURRENT'),
				]
    return [(app, name, value) for app, name, value, type in defaults if include_legacy or type != 'LEGACY']

def validate_bundle(bundle):
    if not os.path.exists(bundle):
        raise UserError("Bundle file does not exist: %s" % bundle)
    if os.path.isdir(bundle):
        raise UserError("Bundle path is a directory: %s" % bundle)
    if not zipfile.is_zipfile(bundle):
        raise UserError("Bundle is not a zip file: %s" % bundle)
    with zipfile.ZipFile(bundle) as zip:
        if not zip.getinfo('metadata.json'):
            raise UserError("Bundle format unknown - can't find metadata.json")
        metadata = json.loads(zip.read('metadata.json'))
        bundle_version = (metadata.get('bundle_type', None), metadata.get('version', None))
        expected = ('apportable_xcode_bundle', BUNDLE_VERSION)
        if bundle_version != expected:
            raise UserError("Version mismatch!  Expected %s but was %s" % (expected, bundle_version))
    # print some stats so we can verify the bundle later
    size = round(os.stat(bundle).st_size / 1024.0 / 1024.0, 2)
    md5 = subprocess.check_output(['md5', '-q', bundle]).strip()
    print ("Bundle is valid! (%s MB, md5: %s)" % (size, md5))

def clean_plugin():
    print ("Cleaning . . . ")
    for name, path in get_component_roots(include_legacy=True):
        if os.path.exists(path):
            shutil.rmtree(path)
    for app, name, value in get_defaults(include_legacy=True):
        subprocess.call(['defaults', 'delete', app, name])
    print ("DONE")


def install_plugin(bundle):
    validate_bundle(bundle)
    clean_plugin()
    print ("Installing from " + bundle)
    component_roots = get_component_roots()
    component_roots_dict = dict(component_roots)
    tempdir = os.path.expanduser("~/Library/Application Support/Developer/Shared/Installer.temp")
    with zipfile.ZipFile(bundle) as zip:
        for arcname in zip.namelist():
            if arcname == "metadata.json":
                metadata = json.loads(zip.read(arcname))
                continue
            component_name, filepath = root_and_path_for_arcname(arcname, component_roots)
            if component_name is None:
                print "Warning: Could not find component for " + arcname
                continue
            zip.extract(arcname, tempdir)
            if not os.path.exists(os.path.dirname(filepath)):
                os.makedirs(os.path.dirname(filepath))
            os.rename(os.path.join(tempdir, arcname), filepath)
    shutil.rmtree(tempdir)
    print ("Installing symlinks")
    for link in metadata['symlinks']:
        arcname = link['arcname']
        arclink = link['arclink']
        name_component, filepath = root_and_path_for_arcname(arcname, component_roots)
        link_component, linkpath = root_and_path_for_arcname(arclink, component_roots)
        os.symlink(linkpath, filepath)
    print ("Setting File Modes")
    for arcname, mode in metadata['modes'].iteritems():
        filepath = root_and_path_for_arcname(arcname, component_roots)[1]
        os.chmod(filepath, mode)
    print ("Setting User Defaults")
    for app, name, value in get_defaults():
        print (' '.join(['defaults', 'write', app, name, value]))
        subprocess.check_call(['defaults', 'write', app, name, value])
        assert value in subprocess.check_output(['defaults', 'read', app, name]), "app:%s name:%s" % (app, name)
    print ("Installation complete - RESTART XCODE NOW")

def root_and_path_for_arcname(arcname, component_roots):
    for root_name, path in component_roots:
        if arcname.startswith(root_name+"/"):
            relative = arcname[len(root_name)+1:]
            filepath = os.path.join(path, relative)
            return root_name, filepath
    return None, arcname


if __name__ == "__main__":
    sys.exit(main())