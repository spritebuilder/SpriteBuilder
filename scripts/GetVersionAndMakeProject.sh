#!/bin/sh

CCB_VERSION="`/usr/libexec/PlistBuddy -c "print :CFBundleVersion" ../SpriteBuilder/ccBuilder/SpriteBuilder-Info.plist`"

# Remove build directory
cd ..
CCB_DIR=$(pwd)

# Update version for about box
echo "Version: $CCB_VERSION" > Generated/Version.txt
echo "GitHub: `git rev-parse --short=10 HEAD`" >> Generated/Version.txt
touch Generated/Version.txt

# Generate default project
echo "=== GENERATING DEFAULT SB-PROJECT ==="
cd Support/PROJECTNAME/
rm -rf PROJECTNAME.xcodeproj/xcuserdata/
rm -rf PROJECTNAME.xcodeproj/project.xcworkspace/xcuserdata
rm ../../Generated/PROJECTNAME.zip
zip -r ../../Generated/PROJECTNAME.zip * -x *.git*
cd ../..


