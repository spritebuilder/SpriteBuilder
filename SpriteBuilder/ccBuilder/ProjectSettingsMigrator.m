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

static NSString *const LOGGER_SECTION = @"ProjectSettings";
static NSString *const LOGGER_ERROR = @"Error";
static NSString *const LOGGER_ROLLBACK = @"Rollback";


@interface ProjectSettingsMigrator ()

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) BackupFileCommand *backupFileCommand;
@property (nonatomic, strong) MoveFileCommand *renameCommand;
@property (nonatomic, strong) MigrationLogger *logger;

@property (nonatomic) BOOL requiresRenamingOfFile;
@property (nonatomic) BOOL requiresMigrationOfProperties;
@property (nonatomic) BOOL requiresRemovalOfObsoleteKeys;

@end


@implementation ProjectSettingsMigrator

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"ProjectSettings must be set");

    self = [super init];
    if (self)
    {
        self.projectSettings = projectSettings;

        [self figureOutWhatNeedsMigration];
    }

    return self;
}

- (void)setLogger:(MigrationLogger *)migrationLogger
{
    _logger = migrationLogger;
}

- (void)figureOutWhatNeedsMigration
{
    NSDictionary *rootKeys = @{
        @"onlyPublishCCBs" : [NSNull null],
        @"exporter" : @"ccbi"
    };

    if ([self rootKeysSet:rootKeys])
    {
        self.requiresRemovalOfObsoleteKeys = YES;
    }

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

    if ([[_projectSettings.projectPath pathExtension] isEqualToString:PROJECT_FILE_CCB_EXTENSION])
    {
        [_logger log:[NSString stringWithFormat:@"Old project file extension '%@' detected.", PROJECT_FILE_CCB_EXTENSION] section:LOGGER_SECTION];
        self.requiresRenamingOfFile = YES;
    }
}

- (NSString *)htmlInfoText
{
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"<ul>"];

    if (_requiresMigrationOfProperties)
    {
        [result appendString:@"<li>Some properties are of an older version.</li>"];
    }

    if (_requiresRenamingOfFile)
    {
        [result appendString:@"<li>Project file has ccbproj extension. Extension will be renamed to sbproj.</li>"];
    }

    if (_requiresRemovalOfObsoleteKeys)
    {
        [result appendString:@"<li>Obsolete settings detected. Those will be removed.</li>"];
    }

    [result appendString:@"</ul>"];

    return result;
}

- (BOOL)isMigrationRequired
{
    return _requiresMigrationOfProperties
        || _requiresRemovalOfObsoleteKeys
        || _requiresRenamingOfFile;
}

- (BOOL)rootKeysSet:(NSDictionary *)rootKeys
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:_projectSettings.projectPath];
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

    [_projectSettings store];

    [self changeExporterToSBI];

    // At the moment there is nothing that can go wrong here
    [self migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites];

    if (![self renameProjectFile:error])
    {
        return NO;
    }

    [_projectSettings store];

    [_logger log:@"Finished successfully!" section:@[LOGGER_SECTION]];

    return YES;
}

- (void)changeExporterToSBI
{
    _projectSettings.exporter = @"sbi";
}

- (BOOL)renameProjectFile:(NSError **)error
{
    NSString *newFileName = [_projectSettings.projectPath replaceExtension:PROJECT_FILE_SB_EXTENSION];

    self.renameCommand = [[MoveFileCommand alloc] initWithFromPath:_projectSettings.projectPath toPath:newFileName];

    if ([_renameCommand execute:error])
    {
        _projectSettings.projectPath = newFileName;
        return YES;
    }

    return NO;
}

- (BOOL)backupProjectFile:(NSError **)error
{
    self.backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:_projectSettings.projectPath];

    NSError *errorBackup;
    if (![_backupFileCommand execute:&errorBackup])
    {
        [_logger log:[NSString stringWithFormat:@"Project file '%@', creating backup file at '%@'.", _projectSettings.projectPath, _backupFileCommand.backupFilePath]
             section:@[LOGGER_SECTION, LOGGER_ERROR]];

        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError userInfo:@{
                NSLocalizedDescriptionKey : @"Could not create backup file for project settings.",
                NSUnderlyingErrorKey : errorBackup
        }];
        return NO;
    };

    [_logger log:[NSString stringWithFormat:@"Project file '%@' creating backup file at '%@'.", _projectSettings.projectPath, _backupFileCommand.backupFilePath]
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

    _projectSettings.projectPath = [_projectSettings.projectPath replaceExtension:PROJECT_FILE_CCB_EXTENSION];

    [_logger log:@"Finished" section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];
}

// Note: To refactor the whole setValue redundancies the convention to name the properties the
// same as in the project settings is necessary to prevent special case mapping code.
- (void)migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites
{
    for (NSString *relativePath in [_projectSettings allResourcesRelativePaths])
    {
        [self migrateTrimSpritesPropertyOfSpriteSheetsForRelPath:relativePath];
    }

    [_projectSettings store];
}

- (void)migrateTrimSpritesPropertyOfSpriteSheetsForRelPath:(NSString *)relPath
{
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
}

- (void)tidyUp
{
    [_backupFileCommand tidyUp];
}

@end
