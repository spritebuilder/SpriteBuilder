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
#import "AllDocumentsMigrator.h"
#import "ResourcePathToPackageMigrator.h"


@implementation MigrationDialogConvenience

+ (ProjectSettings *)migrateWithFilePath:(NSString *)filePath
{
    NSMutableString *renameResult = [NSMutableString string];
    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
        [[ProjectSettingsMigrator alloc] initWithProjectFilePath:filePath renameResult:renameResult],
        [[ResourcePathToPackageMigrator alloc] initWithProjectFilePath:renameResult],
        [[AllDocumentsMigrator alloc] initWithDirPath:[renameResult stringByDeletingLastPathComponent] toVersion:kCCBDictionaryFormatVersion],
        [[AllPackageSettingsMigrator alloc] initWithProjectFilePath:renameResult toVersion:PACKAGE_SETTINGS_VERSION],
        [[CCBToSBRenameMigrator alloc] initWithFilePath:[renameResult stringByDeletingLastPathComponent]]];

    MigrationDialogWindowController *dialog = [[MigrationDialogWindowController alloc] initWithMigrationController:migrationController];

    dialog.title = @"Project Migration";
    dialog.logItemName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    dialog.logHeadline = [NSString stringWithFormat:@"Starting migration of project '%@'", filePath];

    return [dialog startMigration] == SBMigrationDialogResultMigrateSuccessful
       ? [[ProjectSettings alloc] initWithFilepath:renameResult]
       : nil;
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
