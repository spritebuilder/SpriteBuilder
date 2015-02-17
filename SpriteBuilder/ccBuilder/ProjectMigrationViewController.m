#import "ProjectMigrationViewController.h"
#import "ProjectSettings.h"
#import "ProjectMigrationController.h"
#import "NSAlert+Convenience.h"
#import "PackageMigrator.h"
#import "ProjectSettingsMigrator.h"
#import "AllPackageSettingsMigrator.h"


@interface ProjectMigrationViewController ()

@property (nonatomic, strong) ProjectMigrationController *projectMigrationController;

@end

@implementation ProjectMigrationViewController

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"projectSettings must not be nil");

    self = [super init];

    if (self)
    {
        self.projectMigrationController = [[ProjectMigrationController alloc] init];
        _projectMigrationController.delegate = self;
        _projectMigrationController.migrators = @[
                [[PackageMigrator alloc] initWithProjectSettings:projectSettings],
                [[AllPackageSettingsMigrator alloc] initWithProjectSettings:projectSettings],
                [[ProjectSettingsMigrator alloc] initWithProjectSettings:projectSettings]];
    };

    return self;
}

- (BOOL)migrateWithMigrationDetails:(NSString *)migrationDetails
{
    NSAlert *alert = [NSAlert alertWithTitle:@"Package Migration" htmlBodyText:migrationDetails];

    // beware: return value is depending on the position of the button
    [alert addButtonWithTitle:@"Migrate"];
    [alert addButtonWithTitle:@"Close Project"];

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
    if (![_projectMigrationController migrateWithError:&error])
    {
        [NSAlert showModalDialogWithTitle:@"Migration Error" message:error.localizedDescription];
        return NO;
    }
    return YES;
}

@end
