#import "AllPackageSettingsMigrator.h"
#import "MiscConstants.h"
#import "PackageSettings.h"
#import "RMPackage.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "BackupFileCommand.h"
#import "PackageSettingsMigrator.h"
#import "MigrationLogger.h"
#import "PublishResolutions.h"
#import "ProjectSettings.h"
#import "MigratorData.h"
#import "CCEffect_Private.h"


static NSString *const LOGGER_SECTION = @"AllPackageSettingsMigrator";
static NSString *const LOGGER_ERROR = @"Error";
static NSString *const LOGGER_ROLLBACK = @"Rollback";

typedef NSArray *(^LazyPackagePathsGetterBlock)();

@interface AllPackageSettingsMigrator ()

@property (nonatomic, strong) NSMutableArray *packageSettingsCreated;
@property (nonatomic, strong) NSMutableArray *packageSettingsMigrators;
@property (nonatomic) NSUInteger migrationVersionTarget;
@property (nonatomic, strong) NSArray *packagePaths;
@property (nonatomic, strong) MigrationLogger *logger;
@property (nonatomic, copy) LazyPackagePathsGetterBlock packagePathGetterBlock;

@end


@implementation AllPackageSettingsMigrator

- (instancetype)initWithMigratorData:(MigratorData *)migratorData toVersion:(NSUInteger)toVersion
{
    NSAssert(migratorData != nil, @"migratorData must be set");

    return [self initWithPackagePathsGetterBlock:^NSArray *
    {
        ProjectSettings *projectSettings = [[ProjectSettings alloc] initWithFilepath:migratorData.projectSettingsPath];
        if (!projectSettings)
        {
            return nil;
        }

        NSMutableArray *packagePaths = [NSMutableArray array];
        for (NSMutableDictionary *resourcePathDict in projectSettings.packages)
        {
            NSString *fullPackagePath = [projectSettings fullPathForPackageDict:resourcePathDict];
            [packagePaths addObject:fullPackagePath];
        }
        return packagePaths;
    } toVersion:toVersion];
}

- (instancetype)initWithPackagePathsGetterBlock:(LazyPackagePathsGetterBlock)block toVersion:(NSUInteger)toVersion
{
    NSAssert(block != nil, @"block must not be nil");

    self = [super init];

    if (self)
    {
        self.packagePathGetterBlock = block;
        self.migrationVersionTarget = toVersion;
        self.packageSettingsCreated = [NSMutableArray array];
        self.packageSettingsMigrators = [NSMutableArray array];
    }

    return self;
}

- (instancetype)initWithPackagePaths:(NSArray *)packagePaths toVersion:(NSUInteger)toVersion
{
    return [self initWithPackagePathsGetterBlock:^NSArray * {
        return packagePaths;
    } toVersion:toVersion];
}

- (NSArray *)packagePaths
{
    if (!_packagePaths)
    {
        _packagePaths = _packagePathGetterBlock();
    }

    return _packagePaths;
}

- (void)setLogger:(MigrationLogger *)migrationLogger
{
    _logger = migrationLogger;
}

- (BOOL)isMigrationRequired
{
    return [self missingPackageSettings]
           || [self packagesNeedMigration];
}

- (BOOL)packagesNeedMigration
{
    for (NSString *packagePath in self.packagePaths)
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
    for (NSString *packagePath in self.packagePaths)
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

    [_logger log:@"Starting..." section:@[LOGGER_SECTION]];

    if (![self addMissingPackageSettingsWithError:error])
    {
        return NO;
    }

    if (![self migrateAllPackageSettingsWithError:error])
    {
        return NO;
    }

    [_logger log:@"Finished successfully!" section:@[LOGGER_SECTION]];

    return YES;
}

- (BOOL)migrateAllPackageSettingsWithError:(NSError **)error
{
    for (NSString *packagePath in self.packagePaths)
    {
        NSString *fullPackagePath = [packagePath stringByAppendingPathComponent:PACKAGE_PUBLISH_SETTINGS_FILE_NAME];
        PackageSettingsMigrator *packageSettingsMigrator = [[PackageSettingsMigrator alloc] initWithFilepath:fullPackagePath toVersion:_migrationVersionTarget];
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
    for (NSString *packagePath in self.packagePaths)
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
        packageSettings.mainProjectResolutions.resolution_4x = YES;

        if (![packageSettings store])
        {
            [NSError setNewErrorWithErrorPointer:error
                                            code:SBProjectMigrationError
                                         message:[NSString stringWithFormat:@"Could not create default package settings file for package \"%@\"", packagePath]];

            [_logger log:@"Creating missing Package.plist failed." section:@[LOGGER_SECTION, LOGGER_ERROR]];

            return NO;
        }

        [_logger log:[NSString stringWithFormat:@"Creating missing Package.plist file at package '%@'", fullSettingsPath] section:@[LOGGER_SECTION]];

        [_packageSettingsCreated addObject:packageSettings];
    }
    return YES;
}

- (void)rollback
{
    [_logger log:@"Starting..." section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];
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
            [_logger log:[NSString stringWithFormat:@"Could not remove package settings: '%@' : %@", packageSettings.fullPath, error] section:@[LOGGER_SECTION, LOGGER_ROLLBACK, LOGGER_ERROR]];
        }
    }

    [_logger log:@"Finished" section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];
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
