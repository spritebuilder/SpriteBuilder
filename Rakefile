require "rake/clean"

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
    excluded_folders = ["build","tests","cocos2d-tests-android", "cocos2d-ui-tests"]

    Dir.chdir TEMPLATE_PROJECT do
        list = Rake::FileList.new("./**/*", "./Source/libs/cocos2d-iphone/**/*") do |fl|
            fl.exclude "*.git*"
            fl.exclude "*.idea*"
            fl.exclude "*.DS_Store"

            excluded_folders.each { |folder| fl.exclude(/#{folder}/)}
        end
        list.resolve()
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

#
### Rake tasks
#

CLOBBER << "Generated"

directory "Generated"

desc "Build the project template"
file "Generated/#{TEMPLATE_FILENAME}.zip" => ["Generated", *ABSOLUTE_TEMPLATE_FILES] do |task|
    Dir.chdir TEMPLATE_PROJECT do

        output_path = File.join(PROJECT_ROOT, task.name())
        puts output_path
        wrapped_filenames = TEMPLATE_FILES.map { |fn| "\"#{fn}\""}

        #zip in increments to avoid exceeding bash argument list length
        wrapped_filenames.each_slice(100) do |files|
            `zip -q "#{output_path}" #{files.join(" ")}`
        end
    end
end

