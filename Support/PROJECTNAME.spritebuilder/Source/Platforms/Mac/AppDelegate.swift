import Foundation
import Cocoa

@NSApplicationMain
class AppDelegate : NSObject, NSApplicationDelegate
{
    @IBOutlet weak var window : NSWindow!
    @IBOutlet weak var glView : CCGLView!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        var director : CCDirectorMac = CCDirector.sharedDirector() as CCDirectorMac
        
        // enable FPS and SPF
        //director.displayStats = true
        
        // Set a default window size
        var defaultSize = CGSize(width: 480.0, height: 320.0)
        window.setFrame(CGRect(x: 0.0, y: 0.0, width: defaultSize.width, height: defaultSize.height), display: true, animate: false)
        glView.frame = window.frame
        
        // connect the OpenGL view with the director
        director.view = glView
        
        // 'Effects' don't work correctly when autoscale is turned on.
        // Use kCCDirectorResize_NoScale if you don't want auto-scaling.
        //director.resizeMode = kCCDirectorResize_NoScale
        
        // Enable "moving" mouse event. Default no.
        window.acceptsMouseMovedEvents = false
        
        // Center main window
        window.center()
        
        // Configure CCFileUtils to work with SpriteBuilder
        CCBReader.configureCCFileUtils()
        
        CCPackageManager.sharedManager().loadPackages()
        
        director.runWithScene(CCBReader.loadAsScene("MainScene"))
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(theApplication: NSApplication) -> Bool {
        return true;
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        CCPackageManager.sharedManager().savePackages()
        CCDirector.sharedDirector().stopAnimation()     // required to fix stream of GL errors on shutdown
    }
}