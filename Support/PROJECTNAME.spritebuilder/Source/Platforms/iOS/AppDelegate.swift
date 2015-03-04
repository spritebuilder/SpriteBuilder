/*
* SpriteBuilder: http://www.spritebuilder.org
*
* Copyright (c) 2012 Zynga Inc.
* Copyright (c) 2013-2015 Apportable Inc.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import Foundation

@UIApplicationMain
class AppDelegate : CCAppDelegate
{
    override func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Configure Cocos2d with the options set in SpriteBuilder
        
        // TODO: add support for Published-Android support
        var configPath = NSBundle.mainBundle().resourcePath!
        configPath = configPath.stringByAppendingPathComponent("Published-iOS")
        configPath = configPath.stringByAppendingPathComponent("configCocos2d.plist")
        
        let cocos2dSetup = NSMutableDictionary(contentsOfFile: configPath)
        
        // Note: this needs to happen before configureCCFileUtils is called, because we need apportable to correctly setup the screen scale factor.
        #if APPORTABLE
            if cocos2dSetup[CCSetupScreenMode] == CCScreenModeFixed {
            UIScreen.mainScreen().currentMode() = UIScreenMode.emulatedMode(UIScreenAspectFitEmulationMode)
            }
            else {
            UIScreen.mainScreen().currentMode() = UIScreenMode.emulatedMode(UIScreenScaledAspectFitEmulationMode)
            }
        #endif
        
        // Configure CCFileUtils to work with SpriteBuilder
        CCBReader.configureCCFileUtils()
        
        // Do any extra configuration of Cocos2d here (the example line changes the pixel format for faster rendering, but with less colors)
        //cocos2dSetup[CCConfigPixelFormat] = kEAGLColorFormatRGB565
        
        setupCocos2dWithOptions(cocos2dSetup)
        
        return true
    }
    
    override func startScene() -> CCScene {
        return CCBReader.loadAsScene("MainScene")
    }
    
    // example override of UIApplicationDelegate method - be sure to call super!
    override func applicationWillResignActive(application : UIApplication) {
        // let CCAppDelegate handle default behavior
        super.applicationWillResignActive(application)
        
        // add your code here...
    }
}
