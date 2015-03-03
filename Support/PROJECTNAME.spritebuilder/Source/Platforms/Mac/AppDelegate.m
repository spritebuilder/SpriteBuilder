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
