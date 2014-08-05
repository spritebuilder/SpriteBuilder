#!/bin/bash

echo "This script has been depricated and should be replaced with build_distribution.py"
echo "ex: python build_distribution.py -h"
echo "ex: python build_distribution.py --version 1.2"
exit 1


CCB_VERSION=$1
SB_SKU=$2
XCCONFIG="SpriteBuilder.xcconfig"
PRODUCT_NAME=SpriteBuilder
SBPRO_PRIVATE_KEY=fake_private_key

if [ "$#" -lt 2 ]; then
    echo "uasge: ./BuildDistribution.sh <version eg:0.9> <sku eg:[default|pro]> <privateKey (optional)>"
    echo "eg  ./BuildDistribution.sh 0.9 default"
    exit 1
fi

if [ "$SB_SKU" != "pro" ] && [ "$SB_SKU" != "default" ]; then
	echo "Sku must be 'default' or 'pro'"
	exit 1
fi



if [ "$SB_SKU" = "pro" ]; then
	if [ "$#" -lt 3 ]; then
		echo "pro version needs to specify a privateKey"
    	exit 1
	fi

	XCCONFIG="SpriteBuilderPro.xcconfig"
	PRODUCT_NAME=SpriteBuilderPro
	SBPRO_PRIVATE_KEY=$3
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

sh ./scripts/CreateAllGeneratedFiles.sh $CCB_VERSION $SB_SKU

if [ "$SB_SKU" = "pro" ]; then
	if [ ! -e Generated/AndroidXcodePlugin.zip ]; then
		echo "Generated/AndroidXcodePlugin.zip doesn't exist."
	exit 1
	fi	
fi


# Clean and build CocosBuilder
echo "=== CLEANING PROJECT ==="

cd SpriteBuilder/
xcodebuild -alltargets clean | egrep -A 5 "(error):|(SUCCEEDED \*\*)|(FAILED \*\*)"

echo "=== BUILDING SPRITEBUILDER === (please be patient)"


#| egrep -A 5 "(error):|(SUCCEEDED \*\*)|(FAILED \*\*)"
xcodebuild -target SpriteBuilder -configuration Release -xcconfig $XCCONFIG SBPRO_PRIVATE_KEY=\"$SBPRO_PRIVATE_KEY\" build 


# Create archives
echo "=== ZIPPING UP FILES ==="

cd ..
mkdir build
pwd
cp -R SpriteBuilder/build/Release/$PRODUCT_NAME.app build/$PRODUCT_NAME.app
cp -R SpriteBuilder/build/Release/$PRODUCT_NAME.app.dSYM build/$PRODUCT_NAME.app.dSYM

cd build/
zip -q -r "$PRODUCT_NAME.app.dSYM.zip" $PRODUCT_NAME.app.dSYM

echo ""
echo "$PRODUCT_NAME Distribution Build complete!"
echo "You can now open $PRODUCT_NAME/$PRODUCT_NAME.xcodeproj"