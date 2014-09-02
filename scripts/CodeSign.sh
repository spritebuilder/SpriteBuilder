#!/bin/bash

#sandboxed / Appstore
#ID="3rd Party Mac Developer Application: Apportable Inc. (U2K5E32W7G)"


#Non-sandboxed, non-appstore
PKGID="3rd Party Mac Developer Installer: Apportable Inc. (U2K5E32W7G)"


if [ "$1" = "" ]; then
    APP="SpriteBuilder.app"
else
    APP=$1
fi

if [ -a "$APP" ]; then
    echo APP=$APP
else
    echo $APP does not exists. 
    exit 1
fi

if [ "$KEYSTORE" = "" ]; then
    echo Failed to find KEYSTORE for sb.keystore keychain. Specify one with: 'export KEYSTORE=<path>'
    exit 1
fi


if [ "$KEYSTORE_ID" = "" ]; then
    echo Failed to find KEYSTORE_ID. Specify one with: 'export KEYSTORE_ID=<ID>'
    echo Ex: export KEYSTORE_ID="\""Developer ID Application: Apportable Inc. \(U2K5E32W7G\)"\""
    exit 1
fi

if [ "$APP_MODE" = "" ]; then
    echo Failed to find APP_MODE. Specify one with: export APP_MODE=\<entitlements type \(sandboxed,nonsandboxed\)\>
    exit 1
fi

if [ "$APP_MODE" = "sandboxed" ]; then
    ENT="../SpriteBuilder/Sandboxed.entitlements"
fi

if [ "$APP_MODE" = "non_sandboxed" ]; then
    ENT="../SpriteBuilder/NonSandboxed.entitlements"
fi



echo KEYSTORE=$KEYSTORE
echo ENT=$ENT
echo KEYSTORE_ID=$KEYSTORE_ID

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
    codesign --entitlements $ENT  -f --deep --keychain spritebuilder.keychain -s "$KEYSTORE_ID" "$APP/""$1"
 
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

#Use RB App Checker Lite to find things that aren't code signed.

codeSign Contents/Frameworks/HockeySDK.framework/Frameworks/CrashReporter.framework/
codeSign Contents/Frameworks/HockeySDK.framework/Frameworks/CrashReporter.framework/Versions/A/CrashReporter
codeSign Contents/Frameworks/HockeySDK.framework/Frameworks/CrashReporter.framework/Versions/Current/CrashReporter
codeSign Contents/Frameworks/HockeySDK.framework/Versions/A/Frameworks/CrashReporter.framework/
codeSign Contents/Frameworks/HockeySDK.framework/Versions/A/Frameworks/CrashReporter.framework/Versions/A/CrashReporter
codeSign Contents/Frameworks/HockeySDK.framework/Versions/A/Frameworks/CrashReporter.framework/Versions/Current/CrashReporter
codeSign Contents/Frameworks/HockeySDK.framework/Versions/A/HockeySDK
codeSign Contents/Frameworks/HockeySDK.framework/Versions/Current/Frameworks/CrashReporter.framework/Versions/A/CrashReporter
codeSign Contents/Frameworks/Sparkle.framework/Resources/Autoupdate.app/
codeSign Contents/Frameworks/Sparkle.framework/Versions/A/Resources/Autoupdate.app/
codeSign Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle
codeSign Contents/Frameworks/Sparkle.framework/Versions/Current/Resources/Autoupdate.app/
codeSign Contents/Resources/ccz
codeSign Contents/Resources/lame
codeSign Contents/Resources/oggenc
codeSign Contents/Resources/optipng
codeSign Contents/Resources/pngquant

# Sign App
echo codeSign "$APP"
codeSign

# Archive App
productbuild --component "$APP" /Applications --sign "$PKGID" --keychain spritebuilder.keychain --product ../SpriteBuilder/Requirements.plist "$APP.pkg"
deleteKeychain
