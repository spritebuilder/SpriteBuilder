#import "AllPackageSettingsMigrator.h"
#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"
#import "MiscConstants.h"
#import "SBPackageSettings.h"
#import "RMPackage.h"
#import "NSError+SBErrors.h"
#import "SBErrors.h"
#import "BackupFileCommand.h"


@interface AllPackageSettingsMigrator ()

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) NSMutableArray *packageSettingsCreated;
@property (nonatomic, strong) NSMutableArray *backupFileCommands;

@end


@implementation AllPackageSettingsMigrator

- (id)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"projectSettings must not be nil");
    self = [super init];

    if (self)
    {
        self.projectSettings = projectSettings;
        self.packageSettingsCreated = [NSMutableArray array];
        self.backupFileCommands = [NSMutableArray array];
    }

    return self;
}

- (NSString *)htmlInfoText
{
    NSMutableArray *result = [NSMutableArray array];

    if ([self missingPackageSettings])
    {
        [result addObject:@"Some packages are missing the Package.plist file. Default files will be created."];
    }

    if ([self packagesNeedMigration])
    {
        [result addObject:@"Some package settings files will are not up to date. Settings will be migrated."];
    }

    return [result componentsJoinedByString:@"<br/>"];
}

- (BOOL)migrationRequired
{
    return [self missingPackageSettings]
           || [self packagesNeedMigration];
}

- (BOOL)packagesNeedMigration
{
    return NO;
}

- (BOOL)missingPackageSettings
{
    for (NSMutableDictionary *resourcePathDict in _projectSettings.resourcePaths)
    {
        NSString *fullSettingsPath = [[_projectSettings fullPathForResourcePathDict:resourcePathDict] stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:fullSettingsPath])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)migrateWithError:(NSError **)error
{
    if (![self migrationRequired])
    {
        return YES;
    }

    if (![self addMissingPackageSettingsWithError:error])
    {
        return NO;
    }

    if (![self migrateAllPackageSettingsWithError:error])
    {
        return NO;
    }

    return YES;
}

- (BOOL)migrateAllPackageSettingsWithError:(NSError **)error
{
    for (NSMutableDictionary *resourcePathDict in _projectSettings.resourcePaths)
    {
        NSString *fullPackagePath = [_projectSettings fullPathForResourcePathDict:resourcePathDict];

        RMPackage *package = [[RMPackage alloc] init];
        package.dirPath = fullPackagePath;
        SBPackageSettings *packageSettings = [[SBPackageSettings alloc] initWithPackage:package];

        if (![self createBackupfileOfPackageSettings:packageSettings error:error])
        {
            return NO;
        }

        if (![self migratePackageSettings:packageSettings error:NULL])
        {
            return NO;
        }

        [packageSettings store];
    }
    return YES;
}

- (BOOL)migratePackageSettings:(SBPackageSettings *)packageSettings error:(NSError **)error
{
    NSError *underlyingError;
    if (![packageSettings loadWithError:&underlyingError])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError userInfo:@{
                NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Could not open or migrate package settings: \"%@\"", packageSettings
                        .fullPath],
                NSUnderlyingErrorKey : underlyingError
        }];
        return NO;
    };
    return YES;
}

- (BOOL)createBackupfileOfPackageSettings:(SBPackageSettings *)packageSettings error:(NSError **)error
{
    BackupFileCommand *backupFileCommand = [[BackupFileCommand alloc] initWithFilePath:packageSettings.fullPath];
    NSError *backupError;
    if (![backupFileCommand execute:&backupError])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBMigrationError userInfo:@{
            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Could not create backup file of package settings: \"%@\"", packageSettings.fullPath],
            NSUnderlyingErrorKey : backupError
        }];
        return NO;
    }

    [_backupFileCommands addObject:backupFileCommand];

    return YES;
}

- (BOOL)addMissingPackageSettingsWithError:(NSError **)error
{
    for (NSMutableDictionary *resourcePathDict in _projectSettings.resourcePaths)
    {
        NSString *fullPackagePath = [_projectSettings fullPathForResourcePathDict:resourcePathDict];
        NSString *fullSettingsPath = [fullPackagePath stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:fullSettingsPath])
        {
            continue;
        }

        RMPackage *package = [[RMPackage alloc] init];
        package.dirPath = fullPackagePath;

        SBPackageSettings *packageSettings = [[SBPackageSettings alloc] initWithPackage:package];
        if (![packageSettings store])
        {
            [NSError setNewErrorWithErrorPointer:error
                                            code:SBProjectMigrationError
                                         message:[NSString stringWithFormat:@"Could not create default package settings file for package \"%@\"", fullPackagePath]];
            return NO;
        }

        [_packageSettingsCreated addObject:packageSettings];
    }
    return YES;
}

- (void)rollback
{
    for (BackupFileCommand *backupFileCommand in _backupFileCommands)
    {
        NSError *undoError;
        if (![backupFileCommand undo:&undoError])
        {
            NSLog(@"[MIGRATOR] Error Rollback - Could not rollback package settings: \"%@\" : %@", backupFileCommand.filePath, undoError);
        }
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (SBPackageSettings *packageSettings in _packageSettingsCreated)
    {
        NSError *error;
        if (![fileManager removeItemAtPath:packageSettings.fullPath error:&error])
        {
            NSLog(@"[MIGRATOR] Error Rollback - Could not remove package settings: \"%@\" : %@", packageSettings.fullPath, error);
        }
    }
}

@end
