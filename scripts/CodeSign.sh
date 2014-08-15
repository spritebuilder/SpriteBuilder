#!/bin/bash

# ID="3rd Party Mac Developer Application: Apportable Inc. (U2K5E32W7G)"
ID="Developer ID Application: Apportable Inc. (U2K5E32W7G)"
PKGID="3rd Party Mac Developer Installer: Apportable Inc. (U2K5E32W7G)"
ENT="../SpriteBuilder/PlugIns.entitlements"

if [ "$1" = "" ]; then
    APP="SpriteBuilder.app"
else
    APP=$1
fi

echo signing $APP

cd ../build

# Remove signature from PVR tool (as it is already signed)
# rm "$APP/Contents/Resources/PVRTexToolCL"
# codesign --remove-signature "$APP/Contents/Resources/PVRTexToolCL"
# Sign command line tools

function createKeychain() {
    echo Creating spritebuilder.keychain
    security delete-keychain  spritebuilder.keychain
    security create-keychain -p spritebuilder spritebuilder.keychain
    if [ $? != 0 ]; then
        echo Failed to create keychain.
        exit 1
    fi
    
    echo $KEYSTORE/sb.keystore
    security import $KEYSTORE/sb.keystore -k spritebuilder.keychain -f pkcs12 -P spritebuilder -A
    if [ $? != 0 ]; then
        echo Failed to import keystore.
        exit 1
    fi
    security default-keychain -s spritebuilder.keychain
    security unlock-keychain -p spritebuilder spritebuilder.keychain
}

function deleteKeychain() {
    security delete-keychain  spritebuilder.keychain
    security default-keychain -s login.keychain
}

function codeSign() {
    echo CodeSign Func: "$APP/$1"
    codesign --entitlements $ENT  -f --keychain spritebuilder.keychain -s "$ID" "$APP/""$1"
 
    if [ $? != 0 ]; then
        echo Codesign faild. $1
        fail
    fi
}

function fail(){
    deleteKeychain
    exit 1
}

createKeychain
codeSign Contents/Resources/lame
codeSign Contents/Resources/ccz
codeSign Contents/Resources/oggenc
codeSign Contents/Resources/pngquant
codeSign Contents/Resources/optipng
# codeSign Contents/Resources/PVRTexToolCL"

# Sign plug-ins

codeSign Contents/PlugIns/CCBFile.ccbPlugNode
codeSign Contents/PlugIns/CCButton.ccbPlugNode
codeSign Contents/PlugIns/CCControl.ccbPlugNode
codeSign Contents/PlugIns/CCLabelBMFont.ccbPlugNode
codeSign Contents/PlugIns/CCLabelTTF.ccbPlugNode
codeSign Contents/PlugIns/CCLayoutBox.ccbPlugNode
codeSign Contents/PlugIns/CCNode.ccbPlugNode
codeSign Contents/PlugIns/CCNodeColor.ccbPlugNode
codeSign Contents/PlugIns/CCNodeGradient.ccbPlugNode
codeSign Contents/PlugIns/CCParticleSystem.ccbPlugNode
codeSign Contents/PlugIns/CCPhysicsNode.ccbPlugNode
codeSign Contents/PlugIns/CCScrollView.ccbPlugNode
codeSign Contents/PlugIns/CCSlider.ccbPlugNode
codeSign Contents/PlugIns/CCSprite.ccbPlugNode
codeSign Contents/PlugIns/CCSprite9Slice.ccbPlugNode
codeSign Contents/PlugIns/CCTextField.ccbPlugNode
codeSign Contents/PlugIns/CCPhysicsPinJoint.ccbPlugNode
codeSign Contents/PlugIns/CCPhysicsPivotJoint.ccbPlugNode
codeSign Contents/PlugIns/CCPhysicsSpringJoint.ccbPlugNode

codeSign Contents/PlugIns/SBButtonNode.ccbPlugNode
codeSign Contents/PlugIns/SBControlNode.ccbPlugNode
codeSign Contents/PlugIns/SKColorSpriteNode.ccbPlugNode
codeSign Contents/PlugIns/SKFile.ccbPlugNode
codeSign Contents/PlugIns/SKLabelNode.ccbPlugNode
codeSign Contents/PlugIns/SKNode.ccbPlugNode
codeSign Contents/PlugIns/SKSpriteNode.ccbPlugNode

codeSign "Contents/PlugIns/Cocos2d iPhone.ccbPlugExport"

# Sign Frameworks
codeSign Contents/Frameworks/HockeySDK.framework/Versions/Current/Frameworks/CrashReporter.framework
codeSign Contents/Frameworks/HockeySDK.framework
codeSign Contents/Frameworks/Sparkle.framework

# Sign App
echo codeSign "$APP"
codeSign

# Archive App
productbuild --component "$APP" /Applications --sign "$PKGID" --keychain spritebuilder.keychain --product ../SpriteBuilder/Requirements.plist "$APP.pkg"
deleteKeychain
