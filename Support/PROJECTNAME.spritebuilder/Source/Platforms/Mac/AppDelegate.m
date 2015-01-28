#import "AppDelegate.h"
#import "CCPackageManager.h"
#import "CCDirector_Private.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet CC_VIEW<CCView> *glView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Set a default window size
    CGSize defaultWindowSize = CGSizeMake(480.0f, 320.0f);
    
    NSScreen *mainScreen = [NSScreen mainScreen];
    // But optionally, size the window to match the user's screen:
    defaultWindowSize = CGRectInset([mainScreen visibleFrame], 100, 100).size;
    
    [self.window setFrame:CGRectMake(0.0f, 0.0f, defaultWindowSize.width, defaultWindowSize.height) display:true animate:false];
    
    [self.glView setFrame:self.window.frame];
    
    CCDirectorMac *director = (CCDirectorMac*) self.glView.director;
    
    [director reshapeProjection:CC_SIZE_SCALE(defaultWindowSize, director.contentScaleFactor)];
    
    // enable FPS and SPF
    // [director setDisplayStats:YES];
    
    // 'Effects' don't work correctly when autoscale is turned on.
    // Use kCCDirectorResize_NoScale if you don't want auto-scaling.
    //[director setResizeMode:kCCDirectorResize_NoScale];
    
    // Enable "moving" mouse event. Default no.
    [self.window setAcceptsMouseMovedEvents:NO];
    
    // Center main window
    [self.window center];
    
    // Configure CCFileUtils to work with SpriteBuilder
    [CCBReader configureCCFileUtils];
    
    [[CCPackageManager sharedManager] loadPackages];
    
    [CCDirector pushCurrentDirector:director];
    [director presentScene:[CCBReader loadAsScene:@"MainScene"]];
    [CCDirector popCurrentDirector];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[CCPackageManager sharedManager] savePackages];
}

@end
