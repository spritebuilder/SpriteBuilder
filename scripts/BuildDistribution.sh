#!/bin/bash

CCB_VERSION="`/usr/libexec/PlistBuddy -c "print :CFBundleVersion" ../SpriteBuilder/ccBuilder/SpriteBuilder-Info.plist`"

# Clean and build CocosBuilder
cd ..

echo "=== CLEANING ==="

rm -Rf build/
rm -Rf SpriteBuilder/build/

cd SpriteBuilder/
xcodebuild -alltargets clean

echo "=== BUILDING SPRITEBUILDER ==="
xcodebuild -target SpriteBuilder -configuration Debug build

# Create archives
cd ..
# mkdir "build/SpriteBuilder-$CCB_VERSION-examples"
# mkdir "build/SpriteBuilder-$CCB_VERSION-CCBReader"
# cp -RL "Examples" "build/SpriteBuilder-$CCB_VERSION-examples/"
# cp -RL "Examples/SpriteBuilderExample/libs/CCBReader" "build/CocosBuilder-$CCB_VERSION-CCBReader/"

echo "=== ZIPPING UP FILES ==="

cd build/
zip -r "SpriteBuilder-$CCB_VERSION.zip" SpriteBuilder.app
# zip -r "CocosBuilder-$CCB_VERSION-examples.zip" "CocosBuilder-$CCB_VERSION-examples"
# zip -r "CocosBuilder-$CCB_VERSION-CCBReader.zip" "CocosBuilder-$CCB_VERSION-CCBReader"
