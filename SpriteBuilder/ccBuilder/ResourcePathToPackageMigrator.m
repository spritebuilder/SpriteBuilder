#import "ResourcePathToPackageMigrator.h"

#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"
#import "NSString+Packages.h"
#import "PackageImporter.h"
#import "MiscConstants.h"
#import "PackageRenamer.h"
#import "ResourceManager.h"
#import "MigratorData.h"
#import "RMPackage.h"
#import "MoveFileCommand.h"
#import "CreateDirectoryFileCommand.h"
#import "RemoveFileCommand.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "MigrationLogger.h"
#import "MigratorData.h"


static NSString *const LOGGER_SECTION = @"ResourcePathToPackage";
static NSString *const LOGGER_ERROR = @"Error";
static NSString *const LOGGER_ROLLBACK = @"Rollback";

NSString *const PACKAGES_LOG_HASHTAG = @"#packagemigration";


@interface ResourcePathToPackageMigrator ()

@property (nonatomic, strong)ProjectSettings *projectSettings;
@property (nonatomic) BOOL resourcePathWithPackagesFolderNameFound;
@property (nonatomic, copy) NSString *packageAsResourcePathTempName;

@property (nonatomic, strong) NSMutableArray *migrationCommandsStack;
@property (nonatomic, strong) NSMutableArray *resourePathsBackup;
@property (nonatomic, strong) MigrationLogger *logger;

@property (nonatomic, strong) MigratorData *migratorData;

@end


@implementation ResourcePathToPackageMigrator

- (id)initWithMigratorData:(MigratorData *)migratorData
{
    NSAssert(migratorData != nil, @"migratorData must be set");

    self = [super init];
    if (self)
    {
        self.migratorData = migratorData;
        self.resourcePathWithPackagesFolderNameFound = NO;
        self.migrationCommandsStack = [NSMutableArray array];
        self.resourePathsBackup = [NSMutableArray array];
    }

    return self;
}

- (void)setLogger:(MigrationLogger *)migrationLogger
{
    _logger = migrationLogger;
}

- (ProjectSettings *)projectSettings
{
    if (!_projectSettings)
    {
        ProjectSettings *loadedProjectSettings = [[ProjectSettings alloc] initWithFilepath:_migratorData.projectSettingsPath];
        NSAssert(loadedProjectSettings != nil, @"project settings could not be loaded");
        _projectSettings = loadedProjectSettings;
    }

    return _projectSettings;
}

- (BOOL)isMigrationRequired
{
    for (NSMutableDictionary *dict in self.projectSettings.packages)
    {
        NSString *fullPath = [self.projectSettings fullPathForPackageDict:dict];

        if (![fullPath hasPackageSuffix]
            || ![self.projectSettings isPathInPackagesFolder:fullPath])
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

    [self backupResourcePaths];

    // The folder PACKAGE_FOLDER_NAME is special, if it is already taken by a resource
    // path it will be renamed now and restored after importing
    if (![self renameResourcePathCollidingWithPackagesFolderName]
        || ![self createPackagesFolderIfNotExisting])
    {
        [NSError setError:error withError:[self standardError]];
        return NO;
    }

    NSArray *resourcePathsToImport = [self allResourcePathsToBeImported];

    if (![self removeResourcePathsToImportFromProject:resourcePathsToImport]
        || ![self renameCollidingFoldersInPackagesFolderBeforeImporting:resourcePathsToImport]
        || ![self appendPackageSuffixToResourcePathsToImport:resourcePathsToImport]
        || ![self importAndDeleteOldResourcePathsToImport:resourcePathsToImport]
        || ![self restoreCollidingResourcePathName])
    {
        [NSError setError:error withError:[self standardError]];
        return NO;
    }

    [self.projectSettings store];

    [_logger log:@"Finished successfully!" section:@[LOGGER_SECTION]];
    return YES;
}

- (NSError *)standardError
{
    return [NSError errorWithDomain:SBErrorDomain
                               code:SBMigrationError
                           userInfo:@{NSLocalizedDescriptionKey : @"Migration of project to new packages structure failed."}];
}

- (void)backupResourcePaths
{
    [_resourePathsBackup removeAllObjects];
    for (NSMutableDictionary *resourcePath in self.projectSettings.packages)
    {
        [_resourePathsBackup addObject:[resourcePath copy]];
    }
}

- (BOOL)renameCollidingFoldersInPackagesFolderBeforeImporting:(NSArray *)resourcePathsToImport
{
    for (NSMutableString *resourcePath in resourcePathsToImport)
    {
        NSString *futurePackageName = [resourcePath lastPathComponent];
        NSString *futurePackagePath = [self.projectSettings fullPathForPackageName:futurePackageName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:futurePackagePath])
        {
            NSString *newPath = [self rollingRenamedPathForPath:futurePackagePath suffix:@"renamed"];

            if (![self moveFileAndAddToCommandStackAtPath:futurePackagePath toPath:newPath])
            {
                return NO;
            }
        }
    }
    return YES;
}

- (NSArray *)allResourcePathsToBeImported
{
    NSMutableArray *resourcePathsToImport = [NSMutableArray array];

    for (NSMutableDictionary *resourcePathDict in [self.projectSettings.packages copy])
    {
        NSString *fullResourcePath = [self.projectSettings fullPathForPackageDict:resourcePathDict];
        if ([self.projectSettings isPathInPackagesFolder:fullResourcePath])
        {
            continue;
        }

        [resourcePathsToImport addObject:[fullResourcePath mutableCopy]];
    }
    return resourcePathsToImport;
}

- (BOOL)removeResourcePathsToImportFromProject:(NSArray *)resourcePathsToImport
{
    for (NSMutableString *resourcePath in resourcePathsToImport)
    {
        NSError *error;
        if (![self.projectSettings removePackageWithFullPath:resourcePath error:&error])
        {
            [_logger log:[NSString stringWithFormat:@"removing resource path %@ - %@", resourcePath, error.localizedDescription] section:@[LOGGER_SECTION, LOGGER_ERROR]];
            return NO;
        }
    }
    return YES;
}

- (BOOL)appendPackageSuffixToResourcePathsToImport:(NSArray *)resourcePathsToImport
{
    for (NSMutableString *fullPath in resourcePathsToImport)
    {
        if (![fullPath hasPackageSuffix])
        {
            NSString *oldPath = fullPath;
            NSString *newPath = [fullPath stringByAppendingPackageSuffix];

            if (![self moveFileAndAddToCommandStackAtPath:oldPath toPath:newPath])
            {
                return NO;
            }

            [fullPath setString:newPath];
        }
    }
    return YES;
}

- (BOOL)importAndDeleteOldResourcePathsToImport:(NSArray *)resourcePathsToImport
{
    for (NSString *pathToImport in resourcePathsToImport)
    {
        PackageImporter *packageImporter = [[PackageImporter alloc] init];
        packageImporter.projectSettings = self.projectSettings;

        NSError *error;
        if ([packageImporter importPackagesWithPaths:@[pathToImport] error:&error])
        {
            RemoveFileCommand *removeFileCommand = [[RemoveFileCommand alloc] initWithFilePath:pathToImport];

            if (![self executeCommandAndAddToStackOnSuccess:removeFileCommand])
            {
                return NO;
            }
        }
        else
        {
            [_logger log:[NSString stringWithFormat:@"Package importing '%@' failed: %@", pathToImport, error.localizedDescription] section:@[LOGGER_SECTION, LOGGER_ERROR]];
            return NO;
        }
    }
    return YES;
}

- (BOOL)restoreCollidingResourcePathName
{
    if (_resourcePathWithPackagesFolderNameFound)
    {
        PackageRenamer *packageRenamer = [[PackageRenamer alloc] init];
        packageRenamer.projectSettings = self.projectSettings;
        packageRenamer.resourceManager = [ResourceManager sharedManager];

        RMPackage *package = [[RMPackage alloc] init];
        package.dirPath = [self.projectSettings fullPathForPackageName:_packageAsResourcePathTempName];

        NSError *error;
        BOOL success = [packageRenamer renamePackage:package toName:PACKAGES_FOLDER_NAME error:&error];
        if (!success)
        {
            [_logger log:[NSString stringWithFormat:@"Package renaming failed: %@", error.localizedDescription] section:@[LOGGER_SECTION, LOGGER_ERROR]];
        }

        return success;
    }
    return YES;
}

- (BOOL)createPackagesFolderIfNotExisting
{
    return [self packageFolderExists]
           || [self tryToCreatePackagesFolder];

}

- (BOOL)tryToCreatePackagesFolder
{
    NSString *packageFolderPath = [self.projectSettings packagesFolderPath];

    NSAssert(packageFolderPath, @"ProjectSettings' packagesFolderPath not yielding anything, forgot to set projectsettings.projectPath property?");

    CreateDirectoryFileCommand *createDirectoryFileCommand = [[CreateDirectoryFileCommand alloc] initWithDirPath:packageFolderPath];

    return [self executeCommandAndAddToStackOnSuccess:createDirectoryFileCommand];
}

- (BOOL)packageFolderExists
{
    NSString *packageFolderPath = [self.projectSettings packagesFolderPath];

    return [[NSFileManager defaultManager] fileExistsAtPath:packageFolderPath];
}

- (BOOL)renameResourcePathCollidingWithPackagesFolderName
{
    if ([self packageFolderExists]
        && [self isPackageFolderAResourcePath])
    {
        return [self renamePackagesResourcePathFolder];
    }
    return YES;
}

- (BOOL)isPackageFolderAResourcePath
{
    // NOTE: If a resource path is named packages/ or whatever in PACKAGES_FOLDER_NAME is
    // it has to be renamed in order create the packages/ folder
    if ([self.projectSettings isPackageWithFullPathInProject:[self.projectSettings packagesFolderPath]])
    {
        self.resourcePathWithPackagesFolderNameFound = YES;
        return YES;
    }
    return NO;
}

- (BOOL)renamePackagesResourcePathFolder
{
    NSString *renamePathTo = [self renamePathForSpecialCasePackagesFolderAsResourcePath];
    self.packageAsResourcePathTempName = [renamePathTo lastPathComponent];

    NSString *renamePathFrom = [self.projectSettings packagesFolderPath];
    if (![self moveFileAndAddToCommandStackAtPath:renamePathFrom toPath:renamePathTo])
    {
        return NO;
    }

    NSString *newResourcePathName = [renamePathTo lastPathComponent];
    for (NSMutableDictionary *resourcePath in self.projectSettings.packages)
    {
        if ([[self.projectSettings fullPathForPackageDict:resourcePath] isEqualToString:[self.projectSettings packagesFolderPath]])
        {
            // TODO: use ResourcePath object
            resourcePath[@"path"] = [[resourcePath[@"path"] stringByDeletingLastPathComponent] stringByAppendingPathComponent:newResourcePathName];
        }
    }

    return YES;
}

- (NSString *)renamePathForSpecialCasePackagesFolderAsResourcePath
{
    return [self rollingRenamedPathForPath:[self.projectSettings packagesFolderPath] suffix:@"user"];
}

- (NSString *)rollingRenamedPathForPath:(NSString *)path suffix:(NSString *)suffix
{
    NSString *originalPath = path;
    NSString *result = [originalPath stringByAppendingPathExtension:suffix];
    NSUInteger count = 0;

    while ([[NSFileManager defaultManager] fileExistsAtPath:result])
    {
        NSString *renameSuffixWithCount = [NSString stringWithFormat:@"%@.%lu", suffix, count];
        result = [originalPath stringByAppendingPathExtension:renameSuffixWithCount];
        count ++;
    }
    return result;
}

- (BOOL)moveFileAndAddToCommandStackAtPath:(NSString *)fromPath toPath:(NSString *)toPath
{
    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:fromPath toPath:toPath];

    return [self executeCommandAndAddToStackOnSuccess:moveFileCommand];
}

- (BOOL)executeCommandAndAddToStackOnSuccess:(id <FileCommandProtocol>)command
{
    NSError *error;
    BOOL success = [command execute:&error];
    if (success)
    {
        [_logger log:[NSString stringWithFormat:@"Executed successfully - %@", [command description]]
             section:@[LOGGER_SECTION]];

        [_migrationCommandsStack addObject:command];
    }
    else
    {
        [_logger log:[NSString stringWithFormat:@"%@ - %@", [command description], error.localizedDescription]
             section:@[LOGGER_SECTION, LOGGER_ERROR]];
    }
    return success;
}

- (void)rollback
{
    [_logger log:@"Starting..." section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];

    [self rollbackResourcePathChanges];

    [self rollbackFileSystemChanges];

    [_logger log:@"Finished" section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];
}

- (void)rollbackFileSystemChanges
{
    NSArray *reversedStack = [[_migrationCommandsStack reverseObjectEnumerator] allObjects];
    for (id<FileCommandProtocol> command in reversedStack)
    {
        [_logger log:[NSString stringWithFormat:@"Undoing %@", command]
             section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];

        NSError *error;
        if (![command undo:&error])
        {
            [_logger log:[NSString stringWithFormat:@"Undoing %@ - %@", command, error]
                 section:@[LOGGER_SECTION, LOGGER_ROLLBACK, LOGGER_ERROR]];
        }
    }
}

- (void)rollbackResourcePathChanges
{
    [_logger log:[NSString stringWithFormat:@"Resource paths reinstated: %@", _resourePathsBackup] section:@[LOGGER_SECTION, LOGGER_ROLLBACK]];

    self.projectSettings.packages = [_resourePathsBackup copy];

    [self.projectSettings store];
}

@end
