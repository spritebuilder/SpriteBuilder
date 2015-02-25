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
#import "CCBDocument.h"
#import "MiscConstants.h"
#import "CCBDocument.h"

@implementation MigrationControllerFactory

+ (MigrationController *)fullProjectMigrationControllerWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSArray *packagePaths = [self allPackagePathsInProject:projectSettings];

    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
        [[ResourcePathToPackageMigrator alloc] initWithProjectSettings:projectSettings],
        [[AllSBDocumentsMigrator alloc] initWithDirPath:projectSettings.projectPathDir toVersion:kCCBDictionaryFormatVersion],
        [[AllPackageSettingsMigrator alloc] initWithPackagePaths:packagePaths toVersion:PACKAGE_SETTINGS_VERSION],
        [[ProjectSettingsMigrator alloc] initWithProjectSettings:projectSettings],
            [[CCBToSBRenameMigrator alloc] initWithFilePath:projectSettings.projectPathDir renameResult:nil]];

    return migrationController;
}

+ (NSArray *)allPackagePathsInProject:(ProjectSettings *)projectSettings
{
    NSMutableArray *packagePaths = [NSMutableArray array];
    for (NSMutableDictionary *resourcePathDict in projectSettings.resourcePaths)
    {
        NSString *fullPackagePath = [projectSettings fullPathForResourcePathDict:resourcePathDict];
        [packagePaths addObject:fullPackagePath];
    }
    return packagePaths;
}

+ (MigrationController *)documentMigrationControllerWithFilePath:(NSString *)filePath renameResult:(NSMutableDictionary *)renameResult
{
    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
            [[CCBDictionaryMigrator alloc] initWithFilepath:filePath toVersion:kCCBDictionaryFormatVersion],
            [[CCBToSBRenameMigrator alloc] initWithFilePath:filePath renameResult:renameResult]];

    return migrationController;
}

+ (MigrationController *)packageImportingMigrationController:(NSString *)dirPath
{
    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
        [[AllSBDocumentsMigrator alloc] initWithDirPath:dirPath toVersion:kCCBDictionaryFormatVersion],
        [[AllPackageSettingsMigrator alloc] initWithPackagePaths:@[dirPath] toVersion:PACKAGE_SETTINGS_VERSION],
            [[CCBToSBRenameMigrator alloc] initWithFilePath:dirPath renameResult:nil]];

    return migrationController;
}

@end
