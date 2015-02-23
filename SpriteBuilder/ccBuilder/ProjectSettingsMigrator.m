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


@interface ProjectSettingsMigrator ()

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) BackupFileCommand *backupFileCommand;
@property (nonatomic, strong) MoveFileCommand *renameCommand;

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

- (void)figureOutWhatNeedsMigration
{
    if ([self rootKeysSet:@[@"onlyPublishCCBs"]])
    {
        self.requiresRemovalOfObsoleteKeys = YES;
    }

    for (NSString *relativePath in [_projectSettings allResourcesRelativePaths])
    {
        NSNumber *trimSpritesValue = [_projectSettings propertyForRelPath:relativePath andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
        if (trimSpritesValue)
        {
            self.requiresMigrationOfProperties = YES;
            break;
        }
    }

    if ([[_projectSettings.projectPath pathExtension] isEqualToString:PROJECT_FILE_CCB_EXTENSION])
    {
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

- (BOOL)rootKeysSet:(NSArray *)rootKeys
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:_projectSettings.projectPath];

    for (NSString *rootKey in rootKeys)
    {
        if (dict[rootKey])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)migrateWithError:(NSError **)error
{
    if (![self isMigrationRequired])
    {
        return YES;
    }
    
    [_projectSettings store];

    if (![self backupProjectFile:error])
    {
        return NO;
    }

    // At the moment there is nothing that can go wrong here
    [self migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites];

    if (![self renameProjectFile:error])
    {
        return NO;
    }

    [_projectSettings store];

    return YES;
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
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError userInfo:@{
                NSLocalizedDescriptionKey : @"Could not create backup file for project settings.",
                NSUnderlyingErrorKey : errorBackup
        }];
        return NO;
    };
    return YES;
}

- (void)rollback
{
    NSError *error;
    if (![_backupFileCommand undo:&error])
    {
        NSLog(@"[MIGRATION] Error while rolling back project settings migration step: %@", error);
    }

    // The backup is already reinstating the old ccbproj in case it was one
    // Just remove the renamed file.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager removeItemAtPath:_renameCommand.toPath error:&error]
        && error.code != NSFileNoSuchFileError)
    {
        NSLog(@"[MIGRATION] Error while rolling back renaming of project settings: %@", error);
    }

    _projectSettings.projectPath = [_projectSettings.projectPath replaceExtension:PROJECT_FILE_CCB_EXTENSION];
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
            [_projectSettings removePropertyForRelPath:relPath andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
        }
        else
        {
            [_projectSettings setProperty:@YES forRelPath:relPath andKey:RESOURCE_PROPERTY_TRIM_SPRITES];
        }
    }

    if (!dirtyMarked)
    {
        [_projectSettings clearDirtyMarkerOfRelPath:relPath];
    }
}

- (void)tidyUp
{
    [_backupFileCommand tidyUp];
}

@end
