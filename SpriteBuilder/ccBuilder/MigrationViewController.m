#import "MigrationViewController.h"
#import "ProjectSettings.h"
#import "MigrationController.h"
#import "NSAlert+Convenience.h"
#import "ResourcePathToPackageMigrator.h"
#import "ProjectSettingsMigrator.h"
#import "AllPackageSettingsMigrator.h"
#import "MigrationLogger.h"
#import "MigrationLogWindowController.h"
#import "CCBModalSheetController.h"


@interface MigrationViewController ()

@property (nonatomic, strong) MigrationController *migrationController;
@property (nonatomic, strong) MigrationLogger *migrationLogger;
@property (nonatomic, weak) NSWindow *window;

@end

@implementation MigrationViewController

- (instancetype)initWithMigrationController:(MigrationController *)migrationController window:(NSWindow *)window
{
    NSAssert(migrationController != nil, @"migrationController must not be nil");

    self = [super init];

    if (self)
    {
        self.dialogTitle = @"Migration";
        self.cancelButtonTitle = @"Cancel";
        self.migrationLogger = [[MigrationLogger alloc] initWithLogToConsole:NO];
        self.migrationController = [[MigrationController alloc] init];
        self.window = window;

        _migrationController = migrationController;
        _migrationController.delegate = self;
        _migrationController.logger = _migrationLogger ;
    };

    return self;
}

- (BOOL)migrateWithMigrationDetails:(NSString *)migrationDetails
{
    NSAlert *alert = [NSAlert alertWithTitle:_dialogTitle htmlBodyText:migrationDetails];

    [alert addButtonWithTitle:@"Migrate"];
    [alert addButtonWithTitle:_cancelButtonTitle];

    NSInteger returnValue = [alert runModal];
    switch (returnValue)
    {
        case NSAlertFirstButtonReturn:
            return YES;

        case NSAlertSecondButtonReturn:
            return NO;

        default:
            return NO;
    }

    return NO;
}

- (BOOL)migrate
{
    NSError *error;
    if (![_migrationController migrateWithError:&error])
    {
        [NSAlert showModalDialogWithTitle:@"Migration Error" message:error.localizedDescription];

        MigrationLogWindowController *logWindowController = [[MigrationLogWindowController alloc] initWithLogEntries:_migrationLogger.allLogMessages];
        logWindowController.projectName = _projectName;
        [NSApp runModalForWindow:logWindowController.window];

        return NO;
    }
    return YES;
}

@end
