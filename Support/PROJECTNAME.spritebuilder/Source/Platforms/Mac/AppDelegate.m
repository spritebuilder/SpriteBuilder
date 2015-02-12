#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet CCGLView *glView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CCDirectorMac *director = (CCDirectorMac*)[CCDirector sharedDirector];

    // enable FPS and SPF
    // director.displayStats = YES;

    // Set a default window size
    CGSize defaultSize = CGSizeMake(480.0f, 320.0f);
    [_window setFrame:CGRectMake(0.0f, 0.0f, defaultSize.width, defaultSize.height) display:true animate:false];
    _glView.frame = _window.frame;

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
