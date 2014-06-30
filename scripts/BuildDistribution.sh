#!/bin/bash

echo ""

CCB_VERSION=$1
SB_PRO=$2
SB_PRO_PREPROCESSOR=""


if [ "$#" -ne 2 ]; then
    echo "uasge: ./BuildDistribution.sh <version eg:0.9> <sku eg:[default|pro]>"
    echo "eg  ./BuildDistribution.sh 0.9 default"
    exit 1
fi

if [ "$SB_PRO" != "pro" ] && [ "$SB_PRO" != "default" ]; then
	echo "Sku must be 'default' or 'pro'"
	exit 1
fi

if [ "$SB_PRO" = "pro" ]; then
	SB_PRO_PREPROCESSOR="SPRITEBUILDER_PRO=1"; 
fi



# Change to the script's working directory no matter from where the script was called (except if there are symlinks used)
# Solution from: http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo Script working directory: $SCRIPT_DIR
cd "$SCRIPT_DIR"

# Remove build directory
cd ..
CCB_DIR=$(pwd)

rm -Rf build/
rm -Rf SpriteBuilder/build/

sh ./scripts/CreateAllGeneratedFiles.sh $1 $2


# Clean and build CocosBuilder
echo "=== CLEANING PROJECT ==="

cd SpriteBuilder/
xcodebuild -alltargets clean | egrep -A 5 "(error):|(SUCCEEDED \*\*)|(FAILED \*\*)"

echo "=== BUILDING SPRITEBUILDER === (please be patient)"
echo "Additional PreProcessor Defines: $SB_PRO_PREPROCESSOR"

xcodebuild -target SpriteBuilder -configuration Release GCC_PREPROCESSOR_DEFINITIONS='${inherited} $SB_PRO_PREPROCESSOR' build | egrep -A 5 "(error):|(SUCCEEDED \*\*)|(FAILED \*\*)"



# Create archives
echo "=== ZIPPING UP FILES ==="
cd ..
mkdir build
cp -R SpriteBuilder/build/Release/SpriteBuilder.app build/SpriteBuilder.app
cp -R SpriteBuilder/build/Release/SpriteBuilder.app.dSYM build/SpriteBuilder.app.dSYM

cd build/
zip -q -r "SpriteBuilder.app.dSYM.zip" SpriteBuilder.app.dSYM

echo ""
echo "SpriteBuilder Distribution Build complete!"
echo "You can now open SpriteBuilder/SpriteBuilder.xcodeproj"