#import "MigrationControllerFactory.h"
#import "ProjectSettings.h"
#import "AllPackageSettingsMigrator.h"
#import "ResourcePathToPackageMigrator.h"
#import "ProjectSettingsMigrator.h"
#import "MigrationController.h"
#import "PackageSettings.h"

@implementation MigrationControllerFactory

+ (MigrationController *)fullProjectMigrationControllerWithProjectSettings:(ProjectSettings *)projectSettings
{
    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
            [[ResourcePathToPackageMigrator alloc] initWithProjectSettings:projectSettings],
            [[AllPackageSettingsMigrator alloc] initWithProjectSettings:projectSettings toVersion:PACKAGE_SETTINGS_VERSION],
            [[ProjectSettingsMigrator alloc] initWithProjectSettings:projectSettings]];

    return migrationController;
}

@end
