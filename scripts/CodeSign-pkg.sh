#!/bin/bash

ID="3rd Party Mac Developer Application: Apportable Inc. (U2K5E32W7G)"
# ID="Developer ID Application: Apportable Inc. (U2K5E32W7G)"
PKGID="3rd Party Mac Developer Installer: Apportable Inc. (U2K5E32W7G)"
ENT="../SpriteBuilder/PlugIns.entitlements"
APP="SpriteBuilder.app"

cd ../build

#codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/lame"
#codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/ccz"
#codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/oggenc"
#codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/pngquant"
#codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/optipng"

# Archive App
productbuild --component "$APP" /Applications --sign "$PKGID" --product ../SpriteBuilder/Requirements.plist "$APP.pkg"

