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
