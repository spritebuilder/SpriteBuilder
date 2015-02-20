#import "MigrationControllerFactory.h"
#import "ProjectSettings.h"
#import "AllPackageSettingsMigrator.h"
#import "ResourcePathToPackageMigrator.h"
#import "ProjectSettingsMigrator.h"
#import "MigrationController.h"
#import "PackageSettings.h"
#import "CCBDictionaryMigrator.h"
#import "AllSBDocumentsMigrator.h"
#import "CCBDictionaryReader.h"
#import "CCBToSBRenameMigrator.h"
#import "MiscConstants.h"

@implementation MigrationControllerFactory

+ (MigrationController *)fullProjectMigrationControllerWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSMutableArray *packagePaths = [NSMutableArray array];
    for (NSMutableDictionary *resourcePathDict in projectSettings.resourcePaths)
    {
        NSString *fullPackagePath = [projectSettings fullPathForResourcePathDict:resourcePathDict];
        [packagePaths addObject:fullPackagePath];
    }

    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
        [[ResourcePathToPackageMigrator alloc] initWithProjectSettings:projectSettings],
        [[AllSBDocumentsMigrator alloc] initWithDirPath:projectSettings.projectPathDir toVersion:kCCBDictionaryFormatVersion],
        [[AllPackageSettingsMigrator alloc] initWithPackagePaths:packagePaths toVersion:PACKAGE_SETTINGS_VERSION],
        [[ProjectSettingsMigrator alloc] initWithProjectSettings:projectSettings]],
        [[CCBToSBRenameMigrator alloc] initWithDirPath:projectSettings.projectPathDir];

    return migrationController;
}

+ (MigrationController *)documentMigrationControllerWithFilepath:(NSString *)filepath
{
    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
            [[CCBDictionaryMigrator alloc] initWithFilepath:filepath toVersion:0]];

    return migrationController;
}

+ (MigrationController *)packageImportingMigrationController:(NSString *)dirPath
{
    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
        [[AllSBDocumentsMigrator alloc] initWithDirPath:dirPath toVersion:kCCBDictionaryFormatVersion],
        [[AllPackageSettingsMigrator alloc] initWithPackagePaths:@[dirPath] toVersion:PACKAGE_SETTINGS_VERSION],
        [[CCBToSBRenameMigrator alloc] initWithDirPath:dirPath]];

    return migrationController;
}

@end
