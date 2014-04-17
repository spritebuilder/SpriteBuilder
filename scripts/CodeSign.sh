#!/bin/bash

# ID="3rd Party Mac Developer Application: Apportable Inc. (U2K5E32W7G)"
ID="Developer ID Application: Apportable Inc. (U2K5E32W7G)"
PKGID="3rd Party Mac Developer Installer: Apportable Inc. (U2K5E32W7G)"
ENT="../SpriteBuilder/PlugIns.entitlements"
APP="SpriteBuilder.app"

cd ../build

# Remove signature from PVR tool (as it is already signed)
# rm "$APP/Contents/Resources/PVRTexToolCL"
# codesign --remove-signature "$APP/Contents/Resources/PVRTexToolCL"

# Sign command line tools

codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/lame"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/ccz"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/oggenc"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/pngquant"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/optipng"
# codesign --entitlements $ENT -s "$ID" "$APP/Contents/Resources/PVRTexToolCL"

# Sign plug-ins

codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCBFile.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCButton.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCControl.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCLabelBMFont.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCLabelTTF.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCLayoutBox.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCNode.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCNodeColor.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCNodeGradient.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCParticleSystem.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCPhysicsNode.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCScrollView.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCSlider.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCSprite.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCSprite9Slice.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCTextField.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCPhysicsPinJoint.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCPhysicsPivotJoint.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/CCPhysicsSpringJoint.ccbPlugNode"

codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/SBButtonNode.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/SBControlNode.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/SKColorSpriteNode.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/SKFile.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/SKLabelNode.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/SKNode.ccbPlugNode"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/SKSpriteNode.ccbPlugNode"

codesign --entitlements $ENT -s "$ID" "$APP/Contents/PlugIns/Cocos2d iPhone.ccbPlugExport"

# Sign Frameworks
codesign --entitlements $ENT -s "$ID" "$APP/Contents/Frameworks/HockeySDK.framework/Versions/Current/Frameworks/CrashReporter.framework"
codesign --entitlements $ENT -s "$ID" "$APP/Contents/Frameworks/HockeySDK.framework"

# Sign App
codesign --entitlements ../SpriteBuilder/SpriteBuilder.entitlements -s "$ID" "$APP"

# Archive App
productbuild --component "$APP" /Applications --sign "$PKGID" --product ../SpriteBuilder/Requirements.plist "$APP.pkg"

