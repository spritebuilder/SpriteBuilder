#import "Migrator.h"
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
#import "MigratorData.h"


@implementation Migrator

+ (ProjectSettings *)migrateFullProjectWithProjectSettingsFilePath:(NSString *)filePath
{
    MigratorData *migratorData = [[MigratorData alloc] initWithProjectSettingsPath:filePath];

    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
        [[ProjectSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:kCCBProjectSettingsVersion],
        [[ResourcePathToPackageMigrator alloc] initWithMigratorData:migratorData], // ****
        [[AllDocumentsMigrator alloc] initWithDirPath:migratorData.projectPath toVersion:kCCBDictionaryFormatVersion], // ****
        [[AllPackageSettingsMigrator alloc] initWithMigratorData:migratorData toVersion:PACKAGE_SETTINGS_VERSION],
        [[CCBToSBRenameMigrator alloc] initWithFilePath:migratorData.projectPath migratorData:migratorData]
    ];

    MigrationDialogWindowController *dialog = [[MigrationDialogWindowController alloc] initWithMigrationController:migrationController];

    dialog.title = @"Project Migration";
    dialog.logItemName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    dialog.logHeadline = [NSString stringWithFormat:@"Starting migration of project '%@'", filePath];

    return [dialog startMigration] == SBMigrationDialogResultMigrateSuccessful
       ? [[ProjectSettings alloc] initWithFilepath:migratorData.projectSettingsPath]
       : nil;
}

+ (CCBDocument *)migrateDocumentWithFilePath:(NSString *)filePath
                             projectSettings:(ProjectSettings *)projectSettings
{
    MigratorData *migratorData = [[MigratorData alloc] init];


    MigrationController *migrationController = [[MigrationController alloc] init];
    migrationController.migrators = @[
            [[CCBDictionaryMigrator alloc] initWithFilepath:filePath toVersion:kCCBDictionaryFormatVersion],
            [[CCBToSBRenameMigrator alloc] initWithFilePath:filePath migratorData:migratorData]];

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
        NSString *resolvedFilePath = migratorData.renamedFiles[filePath]
            ? migratorData.renamedFiles[filePath]
            : filePath;

        return [[CCBDocument alloc] initWithContentsOfFile:resolvedFilePath];
    }
}

@end
