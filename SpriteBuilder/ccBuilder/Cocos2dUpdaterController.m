#import "Cocos2dUpdaterController.h"
#import "ProjectSettings.h"
#import "AppDelegate.h"
#import "Cocos2dUpdater.h"
#import "NSAlert+Convenience.h"


@interface Cocos2dUpdaterController()

@property (nonatomic, weak, readwrite) AppDelegate *appDelegate;
@property (nonatomic, weak, readwrite) ProjectSettings *projectSettings;
@property (nonatomic, strong) Cocos2dUpdater *cocos2dUpdater;

@end


@implementation Cocos2dUpdaterController

- (instancetype)initWithAppDelegate:(AppDelegate *)appDelegate projectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"Project settings needed to instantiate the updater.");

    self = [super init];
    if (self)
    {
        self.appDelegate = appDelegate;
        self.projectSettings = projectSettings;

    }
    return self;
}

- (void)updateSucceeded
{
    [NSAlert showModalDialogWithTitle:@"Cocos2D Update Complete"
                              message:@"Your project has been updated to use the latest version of Cocos2D.\n\nPlease test your Xcode project. If you encounter any issues check spritebuilder.com for more information."];
}

- (void)updateFailedWithError:(NSError *)error
{
    [NSAlert showModalDialogWithTitle:@"Error updating Cocos2D"
                              message:[NSString stringWithFormat:@"An error occured while updating. Rolling back. \nError: %@\n\nBackup folder restored.", error.localizedDescription]];
}

- (UpdateActions)updateAction:(NSString *)text projectsCocos2dVersion:(NSString *)projectsCocos2dVersion spriteBuildersCocos2dVersion:(NSString *)spriteBuildersCocos2dVersion backupPath:(NSString *)backPath
{
    NSMutableString *informativeText = [NSMutableString string];
    [informativeText appendString:text];
    [informativeText appendFormat:@"\n\nBefore updating we will make a backup of your old Cocos2D folder and rename it to \"%@\".", [backPath lastPathComponent]];

    if (projectsCocos2dVersion)
    {
        [informativeText appendFormat:@"\n\nUpdate from version %@ to %@?", projectsCocos2dVersion, spriteBuildersCocos2dVersion];
    }
    else
    {
        [informativeText appendFormat:@"\n\nUpdate to version %@?", spriteBuildersCocos2dVersion];
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.informativeText = informativeText;
    alert.messageText = @"Cocos2D Automatic Updater";

    // beware: return value is depending on the position of the button
    [alert addButtonWithTitle:@"Update"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Ignore this version"];

    NSInteger returnValue = [alert runModal];
    switch (returnValue)
    {
        case NSAlertFirstButtonReturn: return UpdateActionUpdate;
        case NSAlertSecondButtonReturn: return UpdateActionNothingToDo;
        case NSAlertThirdButtonReturn: return UpdateActionIgnoreVersion;
        default: return UpdateActionNothingToDo;
    }
}

- (void)updateAndBypassIgnore:(BOOL)bypassIgnore
{
    self.cocos2dUpdater = [[Cocos2dUpdater alloc] initWithAppDelegate:_appDelegate projectSettings:_projectSettings];

    [_cocos2dUpdater updateAndBypassIgnore:bypassIgnore];
}

@end
