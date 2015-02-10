require "rake/clean"

PROJECT_ROOT=__FILE__.pathmap("%d")

TEMPLATE_FILENAME="PROJECTNAME"
TEMPLATE_PROJECT = File.join PROJECT_ROOT, "Support", "#{TEMPLATE_FILENAME}.spritebuilder"

TEMPLATE_FILES = Rake::FileList.new("#{TEMPLATE_PROJECT}/**/*", "#{PROJECT_ROOT}/SpriteBuilder/libs/cocos2d-iphone/**/*") do |fl|
    fl.exclude "*.git*"
    fl.exclude "*.idea*"
    fl.exclude "*.DS_Store"

    #don't include unnecessary files in template
    fl.exclude(/\/build/)
    fl.exclude(/\/tests/)
    fl.exclude(/\/cocos2d-tests-android/)
    fl.exclude(/\/cocos2d-ui-tests/)
end


# Rake tasks

CLEAN << "Generated/#{TEMPLATE_FILENAME}.zip" 

directory "Generated"

desc "Build the project template"
file "Generated/#{TEMPLATE_FILENAME}.zip" => ["Generated", *TEMPLATE_FILES] do |task|
    wrapped_filenames = TEMPLATE_FILES.map { |fn| "\"#{fn}\""}
    output_path = File.join(PROJECT_ROOT, task.name())

    #zip in increments to avoid exceeding bash argument list length
    wrapped_filenames.each_slice(100) do |files|
      `zip -q "#{output_path}" #{files.join(" ")}`
    end
end

def list_build_context
    puts "##Project Root"
    puts PROJECT_ROOT
    puts "##Template filename"
    puts TEMPLATE_FILENAME
    puts "##Files to include in template"
    TEMPLATE_FILES.resolve()
    puts TEMPLATE_FILES
end

