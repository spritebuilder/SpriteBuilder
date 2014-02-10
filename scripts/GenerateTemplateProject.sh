#!/bin/bash

PROJECTNAME=$1

# Change to the script's working directory no matter from where the script was called (except if there are symlinks used)
# Solution from: http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR
cd ../Support/$PROJECTNAME.spritebuilder/

# Generate template project
rm -rf $PROJECTNAME.xcodeproj/xcuserdata/
rm -rf $PROJECTNAME.xcodeproj/project.xcworkspace/xcuserdata
rm ../../Generated/$PROJECTNAME.zip
zip -q -r ../../Generated/$PROJECTNAME.zip * -x *.git*
