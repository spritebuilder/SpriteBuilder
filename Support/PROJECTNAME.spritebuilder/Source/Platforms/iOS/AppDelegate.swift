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
