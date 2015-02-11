require "rake/clean"
require "json"

#
### Helper Methods
#

def list_build_context
    puts "##Project Root"
    puts PROJECT_ROOT
    puts "##Template filename"
    puts TEMPLATE_FILENAME
    puts "##Files to include in template"
    puts TEMPLATE_FILES
end

def get_template_files
    #folders to exclude from template via regex match
    excluded_folders = ["xcuserdata", "build","tests","cocos2d-tests-android", "cocos2d-ui-tests"]

    Dir.chdir TEMPLATE_PROJECT do
        list = Rake::FileList.new("./**/*", "./Source/libs/cocos2d-iphone/**/*") do |fl|
            fl.exclude "*.git*"
            fl.exclude "*.idea*"
            fl.exclude "*.DS_Store"

            excluded_folders.each { |folder| fl.exclude(/#{folder}/)}
        end
        list.resolve() #force path evaluation in the context of this directory (relative paths)
        return list
    end
end


#
### Build Constants
#

PROJECT_ROOT=__FILE__.pathmap("%d")
TEMPLATE_FILENAME="PROJECTNAME"
TEMPLATE_PROJECT = File.join PROJECT_ROOT, "Support", "#{TEMPLATE_FILENAME}.spritebuilder"
TEMPLATE_FILES = get_template_files()
ABSOLUTE_TEMPLATE_FILES = TEMPLATE_FILES.map { |f| File.expand_path(File.join(TEMPLATE_PROJECT,f)) }

DEFAULT_SB_VERSION="1.4"
DEFAULT_PRODUCT_NAME="SpriteBuilder"

#
### Rake tasks
#

directory "Generated"

file "Generated/#{TEMPLATE_FILENAME}.zip" => ["Generated", *ABSOLUTE_TEMPLATE_FILES] do |task|
    puts "Generating #{task.name()}..."

    Dir.chdir TEMPLATE_PROJECT do
        output_path = File.join(PROJECT_ROOT, task.name())
        wrapped_filenames = TEMPLATE_FILES.map { |fn| "\"#{fn}\""}

        #zip in increments to avoid exceeding bash argument list length
        wrapped_filenames.each_slice(100) do |files|
            `zip -q "#{output_path}" #{files.join(" ")}`
        end
    end
end

file "Generated/Version.txt" => "Generated" do |task|
    puts "Generating #{task.name()}..."

    version_info = {}
    version_info["version"] = ENV["VERSION"] || DEFAULT_SB_VERSION
    version_info["revision"] = ENV["REVISION"] || `git rev-parse --short=10 HEAD`.chomp

    File.open("Generated/Version.txt","w") << JSON.pretty_generate(version_info)
end

file "Generated/cocos2d_version.txt" => 'SpriteBuilder/libs/cocos2d-iphone/VERSION' do |task|
    puts "Generating #{task.name()}..."

    `cp SpriteBuilder/libs/cocos2d-iphone/VERSION #{task.name()}`
end

namespace :build do
    desc "Build (only) SpriteBuilder's new project template"
    task :template => ["Generated/#{TEMPLATE_FILENAME}.zip"] {}

    desc "Generate all associated files and version info"
    task :generated => [:template, "Generated/Version.txt","Generated/cocos2d_version.txt"] do
    end
end

CLEAN << `find . -type d -name build`.split
CLOBBER << "Generated"
