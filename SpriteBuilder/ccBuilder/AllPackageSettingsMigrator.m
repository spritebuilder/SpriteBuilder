#import "AllPackageSettingsMigrator.h"
#import "MiscConstants.h"
#import "PackageSettings.h"
#import "RMPackage.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "BackupFileCommand.h"
#import "PackageSettingsMigrator.h"


@interface AllPackageSettingsMigrator ()

@property (nonatomic, strong) NSMutableArray *packageSettingsCreated;
@property (nonatomic, strong) NSMutableArray *packageSettingsMigrators;
@property (nonatomic) NSUInteger migrationVersionTarget;

@property (nonatomic, strong) NSArray *packagePaths;
@end


@implementation AllPackageSettingsMigrator

- (id)initWithPackagePaths:(NSArray *)packagePaths toVersion:(NSUInteger)toVersion
{
    NSAssert(packagePaths != nil, @"dirPaths must not be nil");
    NSAssert([packagePaths count] > 0, @"dirPaths should at least contain one path");
    NSAssert(toVersion > 0, @"toVersion must be greate than 0");
    self = [super init];

    if (self)
    {
        self.packagePaths = packagePaths;
        self.migrationVersionTarget = toVersion;
        self.packageSettingsCreated = [NSMutableArray array];
        self.packageSettingsMigrators = [NSMutableArray array];
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

- (BOOL)isMigrationRequired
{
    return [self missingPackageSettings]
           || [self packagesNeedMigration];
}

- (BOOL)packagesNeedMigration
{
    for (NSString *packagePath in _packagePaths)
    {
        NSString *fullPackagePath = [packagePath stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME];
        PackageSettingsMigrator *packageSettingsMigrator = [[PackageSettingsMigrator alloc] initWithFilepath:fullPackagePath toVersion:_migrationVersionTarget];

        if ([packageSettingsMigrator isMigrationRequired])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)missingPackageSettings
{
    for (NSString *packagePath in _packagePaths)
    {
        NSString *fullPackagePath = [packagePath stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:fullPackagePath])
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

    if (![self addMissingPackageSettingsWithError:error])
    {
        return NO;
    }

    return [self migrateAllPackageSettingsWithError:error];
}

- (BOOL)migrateAllPackageSettingsWithError:(NSError **)error
{
    for (NSString *packagePath in _packagePaths)
    {
        NSString *fullPackagePath = [packagePath stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME];
        PackageSettingsMigrator *packageSettingsMigrator = [[PackageSettingsMigrator alloc] initWithFilepath:fullPackagePath  toVersion:_migrationVersionTarget];
        [_packageSettingsMigrators addObject:packageSettingsMigrator];

        if (![packageSettingsMigrator migrateWithError:error])
        {
            return NO;
        }
    }
    return YES;
}

- (BOOL)addMissingPackageSettingsWithError:(NSError **)error
{
    for (NSString *packagePath in _packagePaths)
    {
        NSString *fullSettingsPath = [packagePath stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:fullSettingsPath])
        {
            continue;
        }

        RMPackage *package = [[RMPackage alloc] init];
        package.dirPath = packagePath;

        PackageSettings *packageSettings = [[PackageSettings alloc] initWithPackage:package];
        if (![packageSettings store])
        {
            [NSError setNewErrorWithErrorPointer:error
                                            code:SBProjectMigrationError
                                         message:[NSString stringWithFormat:@"Could not create default package settings file for package \"%@\"", packagePath]];
            return NO;
        }

        [_packageSettingsCreated addObject:packageSettings];
    }
    return YES;
}

- (void)rollback
{
    for (id<MigratorProtocol>migrator in _packageSettingsMigrators)
    {
        [migrator rollback];
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (PackageSettings *packageSettings in _packageSettingsCreated)
    {
        NSError *error;
        if (![fileManager removeItemAtPath:packageSettings.fullPath error:&error])
        {
            NSLog(@"[MIGRATOR] Error Rollback - Could not remove package settings: \"%@\" : %@", packageSettings.fullPath, error);
        }
    }
}

- (void)tidyUp
{
    for (id<MigratorProtocol>migrator in _packageSettingsMigrators)
    {
        if ([migrator respondsToSelector:@selector(tidyUp)])
        {
            [migrator tidyUp];
        }
    }
}

@end
