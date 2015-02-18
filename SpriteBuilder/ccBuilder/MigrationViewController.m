#import "MigrationViewController.h"
#import "ProjectSettings.h"
#import "MigrationController.h"
#import "NSAlert+Convenience.h"
#import "ResourcePathToPackageMigrator.h"
#import "ProjectSettingsMigrator.h"
#import "AllPackageSettingsMigrator.h"


@interface MigrationViewController ()

@property (nonatomic, strong) MigrationController *migrationController;

@end

@implementation MigrationViewController

- (instancetype)initWithMigrationController:(MigrationController *)migrationController
{
    NSAssert(migrationController != nil, @"migrationController must not be nil");

    self = [super init];

    if (self)
    {
        self.dialogTitle = @"Migration";
        self.cancelButtonTitle = @"Cancel";
        self.migrationController = [[MigrationController alloc] init];

        _migrationController.delegate = self;
        _migrationController = migrationController;
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
        return NO;
    }
    return YES;
}

@end
