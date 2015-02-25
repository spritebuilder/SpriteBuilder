#import "AppDelegate.h"
#import "CCPackageManager.h"
#import "CCDirector_Private.h"
#import "PROJECTIDENTIFIERSetup.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[PROJECTIDENTIFIERSetup sharedSetup] setupApplication];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[CCPackageManager sharedManager] savePackages];
}

@end
