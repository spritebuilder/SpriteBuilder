#import "ProjectSettingsMigrator.h"
#import "ResourcePropertyKeys.h"
#import "BackupFileCommand.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "MoveFileCommand.h"
#import "MiscConstants.h"
#import "NSString+Misc.h"
#import "MigrationLogger.h"
#import "MigratorData.h"
#import "ProjectSettings.h"

static NSString *const LOGGER_SECTION = @"ProjectSettings";
static NSString *const LOGGER_ERROR = @"Error";
static NSString *const LOGGER_ROLLBACK = @"Rollback";


@interface ProjectSettingsMigrator ()

@property (nonatomic, strong) BackupFileCommand *backupFileCommand;
@property (nonatomic, strong) MoveFileCommand *renameCommand;
@property (nonatomic, strong) MigrationLogger *logger;

@property (nonatomic) NSUInteger migrationVersionTarget;

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
        self.migrationVersionTarget = toVersion;
    }

    return self;
}

- (void)setLogger:(MigrationLogger *)migrationLogger
{
    _logger = migrationLogger;
}

- (BOOL)requiresMigrationOfProperties
{
    NSDictionary *keyValues = @{
            RESOURCE_PROPERTY_DEPRECATED_KEEP_SPRITES_UNTRIMMED : [NSNull null],
    };

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:_migratorData.projectSettingsPath];
    NSDictionary *resourceProperties = dict[PROJECTSETTINGS_KEY_RESOURCEPROPERTIES];

    for (NSString *key in resourceProperties)
    {
        if ([self areKeysAndValuesSet:keyValues inDictionary:resourceProperties[key] logBlock:nil])
        {
            return YES;
        }
    }
    return NO;
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

- (BOOL)requiresRemovalOfObsoleteRootKeys
{
    NSDictionary *rootKeys = @{
            PROJECTSETTINGS_KEY_DEPRECATED_ONLYPUBLISHCCBS : [NSNull null],
            PROJECTSETTINGS_KEY_DEPRECATED_EXCLUDEFROMPACKAGEMIGRATION : [NSNull null],
        @"exporter" : @"ccbi",
            PROJECTSETTINGS_KEY_DEPRECATED_ENGINE : [NSNull null]
    };

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:_migratorData.projectSettingsPath];
    return [self areKeysAndValuesSet:rootKeys inDictionary:dict logBlock:^(NSString *key, id Value) {
        [_logger log:[NSString stringWithFormat:@"Obsolete root key '%@' detected.", key] section:LOGGER_SECTION];
    }];
}

- (BOOL)isMigrationRequired
{
    return [self requiresMigrationOfProperties]
        || [self requiresRemovalOfObsoleteRootKeys]
        || [self requiresRenamingOfFile];
}

- (BOOL)areKeysAndValuesSet:(NSDictionary *)keysAndValues inDictionary:(NSDictionary *)dictionary logBlock:(void (^)(NSString *key, id Value))logBlock
{
    BOOL result = NO;

    for (NSString *key in keysAndValues)
    {
        if ((dictionary[key] && [keysAndValues[key] isKindOfClass:[NSNull class]])
            || ([dictionary[key] isEqualTo:keysAndValues[key]]))
        {
            if (logBlock)
            {
                logBlock(key, dictionary[key]);
            }
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
    NSDictionary *projectSettingsDict = [NSDictionary dictionaryWithContentsOfFile:_migratorData.projectSettingsPath];

    if (!projectSettingsDict)
    {
        NSString *message = [NSString stringWithFormat:@"Could not load project settings file at '%@'", _migratorData.projectSettingsPath];
        [_logger log:message section:@[LOGGER_SECTION, LOGGER_ERROR]];
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError message:message];
        return NO;
    }

    NSUInteger currentVersion = 1;
    if (projectSettingsDict[PROJECTSETTINGS_KEY_FILEVERSION])
    {
        currentVersion = [projectSettingsDict[PROJECTSETTINGS_KEY_FILEVERSION] unsignedIntegerValue];
        [_logger log:[NSString stringWithFormat:@"project settings version detected: %lu", currentVersion] section:@[LOGGER_SECTION]];
    }

    if (currentVersion == _migrationVersionTarget)
    {
        [_logger log:@"versions are up to date" section:@[LOGGER_SECTION]];
        return YES;
    }

    if (_migrationVersionTarget < currentVersion)
    {
        NSString *message = [NSString stringWithFormat:@"Cannot downgrade version %lu to version %lu", currentVersion, _migrationVersionTarget];
        [_logger log:message section:@[LOGGER_SECTION, LOGGER_ERROR]];
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBMigrationCannotDowngradeError
                                     message:message];
        return NO;
    }

    return [self migrateProjectSettingsDict:projectSettingsDict fromVersion:currentVersion error:error];
}

- (BOOL)migrateProjectSettingsDict:(NSDictionary *)projectSettingsDict fromVersion:(NSUInteger)fromVersion error:(NSError **)error
{
    NSMutableDictionary *result = CFBridgingRelease(CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(projectSettingsDict), kCFPropertyListMutableContainersAndLeaves));;

    NSUInteger currentVersion = fromVersion;
    while (currentVersion < _migrationVersionTarget)
    {
        [_logger log:[NSString stringWithFormat:@"migrating from version %lu to %lu...", currentVersion, currentVersion+1] section:@[LOGGER_SECTION]];

        currentVersion++;

        result = [self migrate:result toVersion:currentVersion withError:error];
        if (!result)
        {
            return NO;
        }
    }

    if (![result writeToFile:_migratorData.projectSettingsPath atomically:YES])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError message:[NSString stringWithFormat:@"Could not overwrite project settings at '%@'", _migratorData.projectSettingsPath]];
        [_logger log:[NSString stringWithFormat:@"Could not overwrite project settings file at '%@'.", _migratorData.projectSettingsPath] section:@[LOGGER_SECTION, LOGGER_ERROR]];

        return NO;
    }
    return YES;
}

- (NSMutableDictionary *)migrate:(NSMutableDictionary *)dictionary toVersion:(NSUInteger)toVersion withError:(NSError **)error
{
    switch (toVersion)
    {
        case 2: return [self migrateToVersion_2:dictionary withError:error];
        default: break;
    }

    [NSError setNewErrorWithErrorPointer:error code:SBPackageSettingsMigrationNoRuleError message:[NSString stringWithFormat:@"Migration rule not found for version %lu", toVersion]];
    return nil;
}

- (NSMutableDictionary *)migrateToVersion_2:(NSMutableDictionary *)dictionary withError:(NSError **)error
{
    // At the moment there is nothing that can go wrong here

    [self migrateRootKeysProjectSettingsDictionary:dictionary];

    [self migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites:dictionary];

    [self doForEveryResource:dictionary block:^(NSString *path, NSMutableDictionary *properties)
    {
        [properties removeObjectForKey:RESOURCE_PROPERTY_DEPRECATED_TABLETSCALE];
    }];

    dictionary[PROJECTSETTINGS_KEY_FILEVERSION] = @2;
    return dictionary;
}

- (void)migrateRootKeysProjectSettingsDictionary:(NSMutableDictionary *)projectSettingsDictionary
{
    projectSettingsDictionary[@"exporter"] = DOCUMENT_BINARY_EXTENSION;
    [projectSettingsDictionary removeObjectForKey:PROJECTSETTINGS_KEY_DEPRECATED_ONLYPUBLISHCCBS];
    [projectSettingsDictionary removeObjectForKey:PROJECTSETTINGS_KEY_DEPRECATED_EXCLUDEFROMPACKAGEMIGRATION];
    [projectSettingsDictionary removeObjectForKey:PROJECTSETTINGS_KEY_DEPRECATED_ENGINE];

    projectSettingsDictionary[PROJECTSETTINGS_KEY_PUBLISHDIR_IOS] = projectSettingsDictionary[PROJECTSETTINGS_KEY_DEPRECATED_PUBLISHDIR_IOS];
    [projectSettingsDictionary removeObjectForKey:PROJECTSETTINGS_KEY_DEPRECATED_PUBLISHDIR_IOS];

    projectSettingsDictionary[@"packages"] = projectSettingsDictionary[PROJECTSETTINGS_KEY_DEPRECATED_RESOURCESPATHS];
    [projectSettingsDictionary removeObjectForKey:PROJECTSETTINGS_KEY_DEPRECATED_RESOURCESPATHS];
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

    [_logger log:[NSString stringWithFormat:@"Could not rename project settings file at '%@' to '%@' with error %@",
                    _migratorData.projectSettingsPath, newFileName, *error] section:@[LOGGER_SECTION, LOGGER_ERROR]];

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

- (void)doForEveryResource:(NSDictionary *)projectSettingsDict block:(void(^)(NSString *path, NSMutableDictionary *properties))block
{
    NSDictionary *resources = projectSettingsDict[PROJECTSETTINGS_KEY_RESOURCEPROPERTIES];
    for (NSString *pathKey in [resources copy])
    {
        NSMutableDictionary *properties = resources[pathKey];
        block(pathKey, properties);
    }
}

- (void)migrateResourcePropertyKeepSpritesUntrimmedToTrimSprites:(NSMutableDictionary *)projectSettingsDict
{
    [self doForEveryResource:projectSettingsDict block:^(NSString *path, NSMutableDictionary *properties)
    {
        if (![properties[RESOURCE_PROPERTY_IS_SMARTSHEET] boolValue])
        {
            return;
        }

        NSNumber *trimSpritesValue = properties[RESOURCE_PROPERTY_DEPRECATED_KEEP_SPRITES_UNTRIMMED];

        if ([trimSpritesValue boolValue])
        {
            [_logger log:[NSString stringWithFormat:@"Removing resource property key '%@' for path '%@'", RESOURCE_PROPERTY_DEPRECATED_KEEP_SPRITES_UNTRIMMED, path] section:LOGGER_SECTION];
            [properties removeObjectForKey:RESOURCE_PROPERTY_DEPRECATED_KEEP_SPRITES_UNTRIMMED];
        }
        else
        {
            [_logger log:[NSString stringWithFormat:@"Setting resource property key '%@' for path '%@'", RESOURCE_PROPERTY_TRIM_SPRITES, path] section:LOGGER_SECTION];
            properties[RESOURCE_PROPERTY_TRIM_SPRITES] = @YES;
        }
    }];
}

- (void)tidyUp
{
    [_backupFileCommand tidyUp];
}

@end
