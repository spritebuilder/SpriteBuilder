#import "MigrationDialogConvenience.h"
#import "CCBDocument.h"
#import "ProjectSettings.h"
#import "MigrationDialogWindowController.h"
#import "CCBToSBRenameMigrator.h"
#import "CCBDictionaryReader.h"
#import "CCBDictionaryMigrator.h"
#import "MigrationController.h"
#import "ProjectSettingsMigrator.h"
#import "PackageSettings.h"
#import "AllPackageSettingsMigrator.h"
#import "AllSBDocumentsMigrator.h"
#import "ResourcePathToPackageMigrator.h"


@implementation MigrationDialogConvenience

+ (ProjectSettings *)migrateFullProject:(ProjectSettings *)projectSettings
{
    NSArray *packagePaths = [self allPackagePathsInProject:projectSettings];

    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
        [[ResourcePathToPackageMigrator alloc] initWithProjectSettings:projectSettings],
        [[AllSBDocumentsMigrator alloc] initWithDirPath:projectSettings.projectPathDir toVersion:kCCBDictionaryFormatVersion],
        [[AllPackageSettingsMigrator alloc] initWithPackagePaths:packagePaths toVersion:PACKAGE_SETTINGS_VERSION],
        [[ProjectSettingsMigrator alloc] initWithProjectSettings:projectSettings],
        [[CCBToSBRenameMigrator alloc] initWithFilePath:projectSettings.projectPathDir]];

    MigrationDialogWindowController *dialog = [[MigrationDialogWindowController alloc] initWithMigrationController:migrationController];

    dialog.title = @"Project Migration";
    dialog.logItemName = [projectSettings projectName];
    dialog.logHeadline = [NSString stringWithFormat:@"Starting migration of project '%@'", projectSettings.projectPathDir];

    SBMigrationDialogResult returnValue = (SBMigrationDialogResult) [dialog startMigration];

    if (returnValue == SBMigrationDialogResultMigrateFailed)
    {
        return nil;
    }
    else
    {
        return projectSettings;
    }
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

+ (CCBDocument *)migrateDocumentWithFilePath:(NSString *)filePath
                             projectSettings:(ProjectSettings *)projectSettings
{
    NSMutableDictionary *migrationResult = [NSMutableDictionary dictionary];

    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
            [[CCBDictionaryMigrator alloc] initWithFilepath:filePath toVersion:kCCBDictionaryFormatVersion],
            [[CCBToSBRenameMigrator alloc] initWithFilePath:filePath renameResult:migrationResult]];

    MigrationDialogWindowController *dialog = [[MigrationDialogWindowController alloc]
            initWithMigrationController:migrationController];

    dialog.title = @"Document Migration";
    dialog.logItemName = [projectSettings projectName];
    dialog.logHeadline = [NSString stringWithFormat:@"Starting migration of document at '%@'", filePath];

    dialog.title = @"Document Migration";
    dialog.logItemName = [NSString stringWithFormat:@"%@-%@", projectSettings.projectName, [filePath lastPathComponent]];

    SBMigrationDialogResult returnValue = (SBMigrationDialogResult) [dialog startMigration];
    if (returnValue == SBMigrationDialogResultMigrateFailed)
    {
        return nil;
    }
    else
    {
        // In case no renaming happened for this file it's safe to open the given filePath
        NSString *resolvedFilePath = migrationResult[filePath]
            ? migrationResult[filePath]
            : filePath;

        return [[CCBDocument alloc] initWithContentsOfFile:resolvedFilePath];
    }
}

@end
