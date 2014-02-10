#!/bin/bash

echo ""

CCB_VERSION=$1

# Change to the script's working directory no matter from where the script was called (except if there are symlinks used)
# Solution from: http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo Script working directory: $SCRIPT_DIR
cd $SCRIPT_DIR

# Remove build directory
cd ..
CCB_DIR=$(pwd)

rm -Rf build/
rm -Rf SpriteBuilder/build/

# Update version for about box
echo "Version: $1" > Generated/Version.txt
echo -n "GitHub: " >> Generated/Version.txt
git rev-parse --short=10 HEAD >> Generated/Version.txt
touch Generated/Version.txt

# Generate default project
echo "=== GENERATING COCOS2D SB-PROJECT ==="
bash scripts/GenerateTemplateProject.sh PROJECTNAME

echo "=== GENERATING SPRITE KIT SB-PROJECT ==="
bash scripts/GenerateTemplateProject.sh SPRITEKITPROJECTNAME

# Clean and build CocosBuilder
echo "=== CLEANING PROJECT ==="

cd SpriteBuilder/
xcodebuild -alltargets clean | egrep -A 5 "(error):|(SUCCEEDED \*\*)|(FAILED \*\*)"

echo "=== BUILDING SPRITEBUILDER === (please be patient)"
xcodebuild -target SpriteBuilder -configuration Release build | egrep -A 5 "(error):|(SUCCEEDED \*\*)|(FAILED \*\*)"

# Create archives
cd ..

mkdir build

# mkdir "build/SpriteBuilder-$CCB_VERSION-examples"
# mkdir "build/SpriteBuilder-$CCB_VERSION-CCBReader"
# cp -RL "Examples" "build/SpriteBuilder-$CCB_VERSION-examples/"
# cp -RL "Examples/SpriteBuilderExample/libs/CCBReader" "build/CocosBuilder-$CCB_VERSION-CCBReader/"

echo "=== COPY PRODUCTS ==="
cp -R SpriteBuilder/build/Release/SpriteBuilder.app build/SpriteBuilder.app
cp -R SpriteBuilder/build/Release/SpriteBuilder.app.dSYM build/SpriteBuilder.app.dSYM

echo "=== ZIPPING UP FILES ==="

cd build/

zip -q -r "SpriteBuilder.app.dSYM.zip" SpriteBuilder.app.dSYM

# zip -r "CocosBuilder-$CCB_VERSION-examples.zip" "CocosBuilder-$CCB_VERSION-examples"
# zip -r "CocosBuilder-$CCB_VERSION-CCBReader.zip" "CocosBuilder-$CCB_VERSION-CCBReader"

echo ""
echo "SpriteBuilder Distribution Build complete!"
echo "You can now open SpriteBuilder/SpriteBuilder.xcodeproj"
