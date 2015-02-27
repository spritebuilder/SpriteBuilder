#import "ProjectSettingsMigrator.h"
#import "ProjectSettings.h"
#import "ResourcePathToPackageMigrator.h"
#import "ResourcePropertyKeys.h"
#import "BackupFileCommand.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "MoveFileCommand.h"
#import "MiscConstants.h"
#import "MoveFileCommand.h"
#import "NSString+Misc.h"
#import "MigrationLogger.h"
#import "MigratorData.h"
#import "CCEffect_Private.h"
#import "CCRendererBasicTypes_Private.h"

static NSString *const LOGGER_SECTION = @"ProjectSettings";
static NSString *const LOGGER_ERROR = @"Error";
static NSString *const LOGGER_ROLLBACK = @"Rollback";


@interface ProjectSettingsMigrator ()

@property (nonatomic, strong) BackupFileCommand *backupFileCommand;
@property (nonatomic, strong) MoveFileCommand *renameCommand;
@property (nonatomic, strong) MigrationLogger *logger;

@property (nonatomic) NSUInteger migrationTargetVersion;

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) MigratorData *migratorData;

@end


@implementation ProjectSettingsMigrator

- (instancetype)initWithMigratorData:(MigratorData *)migratorData toVersion:(NSUInteger)toVersion
{
    NSAssert(migratorData != nil, @"migratorData must be set");
    NSAssert(migratorData.projectSettingsPath != nil, @"migratorData must be set");

    self = [super init];
    if (self)
    {
        self.migratorData = migratorData;
        self.migrationTargetVersion = toVersion;
    }

    return self;
}

- (void)setLogger:(MigrationLogger *)migrationLogger
{
    _logger = migrationLogger;
}

- (BOOL)requiresMigrationOfProperties
{
    BOOL result = NO;

/*
    for (NSString *relativePath in [_projectSettings allResourcesRelativePaths])
    {
        NSNumber *trimSpritesValue = [_projectSettings propertyForRelPath:relativePath andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
        if (trimSpritesValue)
        {
            [_logger log:[NSString stringWithFormat:@"Legacy property key '%@' detected for relative path '%@'.", RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED, relativePath]
                 section:LOGGER_SECTION];

            self.requiresMigrationOfProperties = YES;
        }
    }
*/

    return result;
}

- (BOOL)requiresRenamingOfFile
{
    BOOL result = NO;
    if ([[_migratorData.projectSettingsPath pathExtension] isEqualToString:PROJECT_FILE_CCB_EXTENSION])
    {
        [_logger log:[NSString stringWithFormat:@"Old project file extension '%@' detected.", PROJECT_FILE_CCB_EXTENSION] section:LOGGER_SECTION];
        result =  YES;
    }
    return result;
}

- (BOOL)requiresRemovalOfObsoleteKeys
{
    NSDictionary *rootKeys = @{
        @"onlyPublishCCBs" : [NSNull null],
        @"excludedFromPackageMigration" : [NSNull null],
        @"exporter" : @"ccbi"
    };

    return [self areRootKeysSet:rootKeys];
}

- (BOOL)isMigrationRequired
{
    return [self requiresMigrationOfProperties]
        || [self requiresRemovalOfObsoleteKeys]
        || [self requiresRenamingOfFile];
}

- (BOOL)areRootKeysSet:(NSDictionary *)rootKeys
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:_migratorData.projectSettingsPath];
    BOOL result = NO;

    for (NSString *rootKey in rootKeys)
    {
        if ((dict[rootKey] && [rootKeys[rootKey] isKindOfClass:[NSNull class]])
            || ([dict[rootKey] isEqualTo:rootKeys[rootKey]]))
        {
            [_logger log:[NSString stringWithFormat:@"Obsolete key '%@' detected.", rootKey] section:LOGGER_SECTION];
            result = YES;
        }
    }
    return result;
}

- (BOOL)migrateWithError:(NSError **)error
{
    if (![self isMigrationRequired])
    {
        return YES;
    }

    [_logger log:@"Starting..." section:@[LOGGER_SECTION]];

    if (![self backupProjectFile:error])
    {
        return NO;
    }

    if (![self migrateProjectSettings:error])
    {
        return NO;
    }

    if (![self renameProjectFile:error])
    {
        return NO;
    }

    [_logger log:@"Finished successfully!" section:@[LOGGER_SECTION]];

    return YES;
}

- (BOOL)migrateProjectSettings:(NSError **)error
{
    if (![self migrateRootKeys:error])
    {
        return NO;
    }

    // At the moment there is nothing that can go wrong here
    [self migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites];

    return YES;
}

- (BOOL)migrateRootKeys:(NSError **)error
{
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:_migratorData.projectSettingsPath] mutableCopy];

    dict[@"exporter"] = DOCUMENT_BINARY_EXTENSION;
    [dict removeObjectForKey:@"onlyPublishCCBs"];
    [dict removeObjectForKey:@"excludedFromPackageMigration"];

    if (![dict writeToFile:_migratorData.projectSettingsPath atomically:YES])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError message:@"Could not overwrite project settings file."];
        [_logger log:[NSString stringWithFormat:@"Could not overwrite project settings file at '%@'.", _migratorData.projectSettingsPath] section:@[LOGGER_SECTION, LOGGER_ERROR]];
        return NO;
    }
    return YES;
}

- (BOOL)renameProjectFile:(NSError **)error
{
    NSString *newFileName = [_migratorData.projectSettingsPath replaceExtension:PROJECT_FILE_SB_EXTENSION];

    self.renameCommand = [[MoveFileCommand alloc] initWithFromPath:_migratorData.projectSettingsPath toPath:newFileName];
    if ([_renameCommand execute:error])
    {
        _migratorData.renamedFiles[_migratorData.projectSettingsPath] = newFileName;
        _migratorData.projectSettingsPath = newFileName;
        return YES;
    }

    [_logger log:[NSString stringWithFormat:@"Could not rename project settings file at '%@' to '%@' with error %@", _filePath, newFileName, *error] section:@[LOGGER_SECTION, LOGGER_ERROR]];

    return NO;
}

- (BOOL)backupProjectFile:(NSError **)error
{
    self.backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:_migratorData.projectSettingsPath];

    NSError *errorBackup;
    if (![_backupFileCommand execute:&errorBackup])
    {
        [_logger log:[NSString stringWithFormat:@"Project file '%@', creating backup file at '%@'.", _migratorData.projectSettingsPath, _backupFileCommand.backupFilePath]
             section:@[LOGGER_SECTION, LOGGER_ERROR]];

        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError userInfo:@{
                NSLocalizedDescriptionKey : @"Could not create backup file for project settings.",
                NSUnderlyingErrorKey : errorBackup
        }];
        return NO;
    };

    [_logger log:[NSString stringWithFormat:@"Project file '%@' creating backup file at '%@'.", _migratorData.projectSettingsPath, _backupFileCommand.backupFilePath]
         section:LOGGER_SECTION];

    return YES;
}

- (void)rollback
{
    [_logger log:@"Starting..." section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];

    NSError *error;
    if (![_backupFileCommand undo:&error])
    {
        [_logger log:[NSString stringWithFormat:@"recovering project file from backup at '%@' : %@", _backupFileCommand.backupFilePath, error]
             section:@[LOGGER_SECTION, LOGGER_ROLLBACK, LOGGER_ERROR]];
    }

    // The backup is already reinstating the old ccbproj in case it was one
    // Just remove the renamed file.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager removeItemAtPath:_renameCommand.toPath error:&error]
        && error.code != NSFileNoSuchFileError)
    {
        [_logger log:[NSString stringWithFormat:@"Removing new %@ project file at '%@' : %@", PROJECT_FILE_SB_EXTENSION, _renameCommand.toPath, error]
             section:@[LOGGER_SECTION, LOGGER_ROLLBACK, LOGGER_ERROR]];
    }

    [_logger log:@"Finished" section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];
}

// Note: To refactor the whole setValue redundancies the convention to name the properties the
// same as in the project settings is necessary to prevent special case mapping code.
- (void)migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites
{
/*
    for (NSString *relativePath in [_projectSettings allResourcesRelativePaths])
    {
        [self migrateTrimSpritesPropertyOfSpriteSheetsForRelPath:relativePath];
    }

    [_projectSettings store];
*/
}

- (void)migrateTrimSpritesPropertyOfSpriteSheetsForRelPath:(NSString *)relPath
{
/*
    if (![[_projectSettings propertyForRelPath:relPath andKey:RESOURCE_PROPERTY_IS_SMARTSHEET] boolValue])
    {
        return;
    }

    BOOL dirtyMarked = [_projectSettings isDirtyRelPath:relPath];
    NSNumber *trimSpritesValue = [_projectSettings propertyForRelPath:relPath andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
    if (trimSpritesValue)
    {
        if ([trimSpritesValue boolValue])
        {
            [_logger log:[NSString stringWithFormat:@"Removing resource property key '%@' for path '%@'", RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED, relPath] section:LOGGER_SECTION];
            [_projectSettings removePropertyForRelPath:relPath andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
        }
        else
        {
            [_logger log:[NSString stringWithFormat:@"Setting resource property key '%@' for path '%@'", RESOURCE_PROPERTY_TRIM_SPRITES, relPath] section:LOGGER_SECTION];
            [_projectSettings setProperty:@YES forRelPath:relPath andKey:RESOURCE_PROPERTY_TRIM_SPRITES];
        }
    }

    if (!dirtyMarked)
    {
        [_logger log:[NSString stringWithFormat:@"Marking resource '%@' as dirty", relPath] section:LOGGER_SECTION];
        [_projectSettings clearDirtyMarkerOfRelPath:relPath];
    }
*/
}

- (void)tidyUp
{
    [_backupFileCommand tidyUp];
}

@end
