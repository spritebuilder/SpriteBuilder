#!/bin/bash

CCB_VERSION=$1

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
cd Support/PROJECTNAME.spritebuilder/
rm -rf PROJECTNAME.xcodeproj/xcuserdata/
rm -rf PROJECTNAME.xcodeproj/project.xcworkspace/xcuserdata
rm ../../Generated/PROJECTNAME.zip
zip -r ../../Generated/PROJECTNAME.zip * -x *.git*
cd ../..

echo "=== GENERATING SPRITE KIT SB-PROJECT ==="
cd Support/SPRITEKITPROJECTNAME.spritebuilder/
rm -rf SPRITEKITPROJECTNAME.xcodeproj/xcuserdata/
rm -rf SPRITEKITPROJECTNAME.xcodeproj/project.xcworkspace/xcuserdata
rm ../../Generated/SPRITEKITPROJECTNAME.zip
zip -r ../../Generated/SPRITEKITPROJECTNAME.zip * -x *.git*
cd ../..

# Clean and build CocosBuilder
echo "=== CLEANING ==="

cd SpriteBuilder/
xcodebuild -alltargets clean

echo "=== BUILDING SPRITEBUILDER ==="
xcodebuild -target SpriteBuilder -configuration Release build

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

zip -r "SpriteBuilder.app.dSYM.zip" SpriteBuilder.app.dSYM

# zip -r "CocosBuilder-$CCB_VERSION-examples.zip" "CocosBuilder-$CCB_VERSION-examples"
# zip -r "CocosBuilder-$CCB_VERSION-CCBReader.zip" "CocosBuilder-$CCB_VERSION-CCBReader"
