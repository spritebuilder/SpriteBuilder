import Foundation
import Cocoa

@NSApplicationMain
class AppDelegate : NSObject, NSApplicationDelegate
{
    @IBOutlet weak var window : NSWindow!
    @IBOutlet weak var glView : CCGLView!
    
    func titleBarHeight() -> CGFloat {
        let frame = NSRect(x:0, y:0, width:200, height:200)
        let contentRect = NSWindow.contentRectForFrameRect(frame, styleMask: NSTitledWindowMask)
        return (frame.size.height - contentRect.size.height)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        var director : CCDirectorMac = CCDirector.sharedDirector() as CCDirectorMac
        
        // enable FPS and SPF
        //director.displayStats = true
        
        // Set a default window size
        var defaultSize = CGSize(width: 480, height: 320)
        // window height must be increased by titleBarHeight to prevent the view being obstructed by the title bar
        window.setFrame(CGRect(x: 0, y: 0, width: defaultSize.width, height: defaultSize.height + titleBarHeight()), display: true, animate: false)
        glView.frame = CGRect(x: 0, y: 0, width: defaultSize.width, height: defaultSize.height)

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