#import "ProjectSettingsMigrator.h"
#import "ProjectSettings.h"
#import "ResourcePathToPackageMigrator.h"
#import "ResourcePropertyKeys.h"
#import "BackupFileCommand.h"
#import "NSError+SBErrors.h"
#import "Errors.h"


@interface ProjectSettingsMigrator ()

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) BackupFileCommand *backupFileCommand;

@end


@implementation ProjectSettingsMigrator

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"ProjectSettings must be set");

    self = [super init];
    if (self)
    {
        self.projectSettings = projectSettings;
    }

    return self;
}

- (NSString *)htmlInfoText
{
    return @"Old property setting for untrimmed Sprite Sheets found. Project settings file will change after migration.";
}

- (BOOL)isMigrationRequired
{
    for (NSString *relativePath in [_projectSettings allResourcesRelativePaths])
    {
        NSNumber *trimSpritesValue = [_projectSettings propertyForRelPath:relativePath andKey:RESOURCE_PROPERTY_LEGACY_KEEP_SPRITES_UNTRIMMED];
        if (trimSpritesValue)
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

    [self migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites];

    return YES;
}

- (void)rollback
{
    NSError *error;
    if (![_backupFileCommand undo:&error])
    {
        NSLog(@"[MIGRATION] Error while rolling back project settings migration step: %@", error);
    }
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
