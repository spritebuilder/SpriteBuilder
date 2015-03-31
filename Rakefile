require "rake/clean"
require "json"
require "fileutils"

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
    excluded_folders = ["xcuserdata", "build","tests","cocos2d-tests-android", "cocos2d-ui-tests", "UnitTests"]

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

def call_xctool command
    reporter = "-reporter pretty"

    if ENV["CIRCLE_CI"]
        reporter = "-reporter plain -reporter junit:test_results.xml"
    end

    sh "xctool #{reporter} #{command}"
end

def get_artifact_name
    return @artifact_name if @artifact_name
    branch = `git rev-parse --abbrev-ref HEAD`.chomp
    hash = `git rev-parse --short=10 HEAD`.chomp
    date = Time.now.strftime("%d/%m/%Y-%H.%M")

    @artifact_name = "#{branch}-#{hash}-#{date}".gsub(/[^0-9A-z.\-]/, '_')
end

def check_required_programs
    `which xctool`
    unless $?.success?
        return "xctool not detected - run `brew install xctool`"
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
DERIVED_DATA_LOCATION="~/Library/Developer/Xcode/DerivedData"
DEFAULT_SB_VERSION=`cat VERSION`.chomp
DEFAULT_PRODUCT_NAME="SpriteBuilder"

BUILD_DIR=File.join PROJECT_ROOT, "Output"

#
### Rake tasks
#

directory "Generated"
directory BUILD_DIR

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
    version_info["version"] = DEFAULT_SB_VERSION
    version_info["revision"] = ENV["REVISION"] || `git rev-parse --short=10 HEAD`.chomp

    f = File.open("Generated/Version.txt","w")
    f.write JSON.pretty_generate(version_info)
    f.close
end

file "Generated/cocos2d_version.txt" => 'SpriteBuilder/libs/cocos2d-iphone/VERSION' do |task|
    puts "Generating #{task.name()}..."

    `cp SpriteBuilder/libs/cocos2d-iphone/VERSION #{task.name()}`
end

task :build_requirements do
    requirement_missing = check_required_programs
    fail requirement_missing if requirement_missing
end

namespace :build do
    desc "Build (only) SpriteBuilder's new project template"
    task :template => ["Generated/#{TEMPLATE_FILENAME}.zip"] {}

    desc "Generate all associated files and version info"
    task :generated => [:template, "Generated/Version.txt","Generated/cocos2d_version.txt"] do
    end

    task :tests => [:generated,:build_requirements] do
        call_xctool "-configuration Testing build-tests"
    end
end

task :default => "build:generated"

desc "Run SpriteBuilder unit tests"
task :test => ["build:tests", :build_requirements] do
    call_xctool "-configuration Testing run-tests"
end

namespace :package do
    desc "Create SpriteBuilder.app + zip app and symbols"
    task :app do
        call_xctool "TARGET_BUILD_DIR=#{BUILD_DIR} CONFIGURATION_BUILD_DIR=#{BUILD_DIR} VERSION=#{DEFAULT_SB_VERSION} -configuration Release build"
        app, symbols = "NONE"

        built_files = `find . -name SpriteBuilder.app`.chomp.split "\n"

        app = built_files.max {|a,b| File.mtime(a) <=> File.mtime(b)}
        symbols = "#{app}.dSYM"
        versioned_app_name = "#{DEFAULT_PRODUCT_NAME}-#{DEFAULT_SB_VERSION}.app"

        unless File.exists? app and File.exists? symbols
            fail "Built products don't exist at #{app} and #{symbols}"
        end

        FileUtils.cp_r app, File.join(BUILD_DIR,versioned_app_name)

        Dir.chdir BUILD_DIR do
            `zip -q -r #{versioned_app_name}.zip #{versioned_app_name}`
            `zip -q -r SpriteBuilder.app.dSYM.zip SpriteBuilder.app.dSYM`
        end
    end

    desc "Create SpriteBuilder.xcarchive and zip"
    task :archive do
        call_xctool "TARGET_BUILD_DIR=#{BUILD_DIR} VERSION='#{DEFAULT_SB_VERSION}' -configuration Release archive -archivePath #{BUILD_DIR}/SpriteBuilder"

        Dir.chdir BUILD_DIR do
            sh "zip -r SpriteBuilder.xcarchive.zip SpriteBuilder.xcarchive"
        end
    end
end

desc "Build SpriteBuilder distribution"
task :package => [:clobber, BUILD_DIR, :build_requirements] do

    #force generation of a new Version.txt 
    Rake::Task["build:generated"].invoke
    Rake::Task["package:app"].invoke

    Rake::Task["clean"].invoke
    Rake::Task["package:archive"].invoke

    if ENV["CIRCLE_CI"]
        Dir.chdir BUILD_DIR do
            sh "echo Copying artifacts.."
            sh "cp *.zip $CIRCLE_ARTIFACTS"
        end
    end
end

build_dirs =  `find . -type d -iname build`.split
CLEAN.include *build_dirs
CLOBBER.include *["Generated", "Build"]
