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

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet CCGLView *glView;
@end

@implementation AppDelegate

- (float)titleBarHeight
{
    NSRect frame = NSMakeRect (0, 0, 200, 200);
    NSRect contentRect;
    contentRect = [NSWindow contentRectForFrameRect:frame styleMask:NSTitledWindowMask];
    return (frame.size.height - contentRect.size.height);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CCDirectorMac *director = (CCDirectorMac*)[CCDirector sharedDirector];

    // enable FPS and SPF
    // director.displayStats = YES;

    // Set a default window size
    CGSize defaultSize = CGSizeMake(480.0f, 320.0f);
    // window height must be extended by titleBarHeight to fully fit the view with its defaultSize in the window
    [_window setFrame:CGRectMake(0, 0, defaultSize.width, defaultSize.height + [self titleBarHeight]) display:true animate:false];
    [_glView setFrame:CGRectMake(0, 0, defaultSize.width, defaultSize.height)];

    // connect the OpenGL view with the director
    director.view = _glView;

    // 'Effects' don't work correctly when autoscale is turned on.
    // Use kCCDirectorResize_NoScale if you don't want auto-scaling.
    //director.resizeMode = kCCDirectorResize_NoScale;

    // Enable "moving" mouse event. Default no.
    _window.acceptsMouseMovedEvents = NO;

    // Center main window
    [_window center];

    // Configure CCFileUtils to work with SpriteBuilder
    [CCBReader configureCCFileUtils];
    
    [[CCPackageManager sharedManager] loadPackages];

    [director runWithScene:[CCBReader loadAsScene:@"MainScene"]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[CCPackageManager sharedManager] savePackages];
    [[CCDirector sharedDirector] stopAnimation];    // required to fix stream of GL errors on shutdown
}

@end
