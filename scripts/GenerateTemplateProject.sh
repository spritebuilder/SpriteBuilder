#!/bin/bash

PROJECTNAME=$1

# Change to the script's working directory no matter from where the script was called (except if there are symlinks used)
# Solution from: http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"
cd ../Support/$PROJECTNAME.spritebuilder/

# Generate template project
echo Generating: $PROJECTNAME

# only remove files if they exist
if [ -d $PROJECTNAME.xcodeproj/xcuserdata/ ]; then
	rm -rf $PROJECTNAME.xcodeproj/xcuserdata/
fi
if [ -d $PROJECTNAME.xcodeproj/project.xcworkspace/xcuserdata/ ]; then
	rm -rf $PROJECTNAME.xcodeproj/project.xcworkspace/xcuserdata/
fi
if [ -f ../../Generated/$PROJECTNAME.zip ]; then
	rm ../../Generated/$PROJECTNAME.zip
fi

zip -q -r ../../Generated/$PROJECTNAME.zip * -x *.git* */tests/*

# Adds default project .gitignore file to archive
cp ../default_projects.gitignore ./.gitignore
zip -q ../../Generated/$PROJECTNAME.zip .gitignore
rm .gitignore

echo ""