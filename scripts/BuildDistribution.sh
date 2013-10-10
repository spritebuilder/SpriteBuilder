#!/bin/bash

CCB_VERSION=$1

# Remove build directory
cd ..
rm -Rf build/
rm -Rf SpriteBuilder/build/

# Update version for about box
echo "Version: $1" > Generated/Version.txt
echo -n "GitHub: " >> Generated/Version.txt
git rev-parse --short=10 HEAD >> Generated/Version.txt
touch Generated/Version.txt

# Clean and build CocosBuilder
cd SpriteBuilder/
xcodebuild -alltargets clean
xcodebuild -target SpriteBuilder -configuration Debug build

# Create archives
cd ..
# mkdir "build/SpriteBuilder-$CCB_VERSION-examples"
# mkdir "build/SpriteBuilder-$CCB_VERSION-CCBReader"
# cp -RL "Examples" "build/SpriteBuilder-$CCB_VERSION-examples/"
# cp -RL "Examples/SpriteBuilderExample/libs/CCBReader" "build/CocosBuilder-$CCB_VERSION-CCBReader/"

cd build/
zip -r "SpriteBuilder-$CCB_VERSION.zip" SpriteBuilder.app
# zip -r "CocosBuilder-$CCB_VERSION-examples.zip" "CocosBuilder-$CCB_VERSION-examples"
# zip -r "CocosBuilder-$CCB_VERSION-CCBReader.zip" "CocosBuilder-$CCB_VERSION-CCBReader"
