#import "MigrationControllerFactory.h"
#import "ProjectSettings.h"
#import "AllPackageSettingsMigrator.h"
#import "ResourcePathToPackageMigrator.h"
#import "ProjectSettingsMigrator.h"
#import "MigrationController.h"

@implementation MigrationControllerFactory

+ (MigrationController *)fullProjectMigrationControllerWithProjectSettings:(ProjectSettings *)projectSettings
{
    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
        [[ResourcePathToPackageMigrator alloc] initWithProjectSettings:projectSettings],
        [[AllPackageSettingsMigrator alloc] initWithProjectSettings:projectSettings],
        [[ProjectSettingsMigrator alloc] initWithProjectSettings:projectSettings]];

    return migrationController;
}

@end
