#import <MacTypes.h>
#import "PackageMigrator.h"

#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"
#import "NSString+Packages.h"
#import "PackageImporter.h"
#import "MiscConstants.h"
#import "PackageRenamer.h"
#import "ResourceManager.h"
#import "RMPackage.h"
#import "MoveFileCommand.h"
#import "CreateDirectoryFileCommand.h"
NSString *const PACKAGES_LOG_HASHTAG = @"#packagemigration";

#define LocalLogDebug( s, ... ) NSLog( @"[DEBUG] <%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#define LocalLogError( s, ... ) NSLog( @"[ERROR] <%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )

@interface PackageMigrator ()

@property (nonatomic, weak)ProjectSettings *projectSettings;
@property (nonatomic) BOOL resourcePathWithPackagesFolderNameFound;
@property (nonatomic, copy) NSString *packageAsResourcePathTempName;

@property (nonatomic, strong) NSMutableArray *migrationCommandsStack;
@property (nonatomic, strong) NSMutableArray *resourePathsBackup;

@end


@implementation PackageMigrator

- (instancetype)init
{
    NSLog(@"Create instances of %@ with designated initializer.", [self class]);
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    self = [super init];
    if (self)
    {
        self.projectSettings = projectSettings;
        self.resourcePathWithPackagesFolderNameFound = NO;
        self.migrationCommandsStack = [NSMutableArray array];
        self.resourePathsBackup = [NSMutableArray array];
    }

    return self;
}

- (BOOL)migrate:(NSError **)error
{
    LocalLogDebug(@"Package migration started...");
    [self backupResourcePaths];

    // The folder PACKAGE_FOLDER_NAME is special, if it is already taken by a resource
    // path it will be renamed now and restore after importing
    if (![self renameResourcePathCollidingWithPackagesFolderName:error])
    {
        return NO;
    }

    if (![self createPackagesFolderIfNotExisting:error])
    {
        return NO;
    }

    NSArray *resourcePathsToImport = [self allResourcePathsToBeImported];

    if (![self removeResourcePathsToImportFromProject:resourcePathsToImport error:error])
    {
        return NO;
    }

    if (![self renameCollidingFoldersInPackagesFolderBeforeImporting:resourcePathsToImport error:error])
    {
        return NO;
    }

    if (![self appendPackageSuffixToResourcePathsToImport:resourcePathsToImport error:error])
    {
        return NO;
    }

    if (![self importAndDeleteOldResourcePathsToImport:resourcePathsToImport error:error])
    {
        return NO;
    }

    if (![self restoreCollidingResourcePathName:error])
    {
        return NO;
    }

    // NSLog(@"%@", _migrationCommandsStack);

    LocalLogDebug(@"Package finished successfully!");
    return YES;
}

- (void)backupResourcePaths
{
    [_resourePathsBackup removeAllObjects];
    for (NSMutableDictionary *resourcePath in _projectSettings.resourcePaths)
    {
        [_resourePathsBackup addObject:[resourcePath copy]];
    }
}

- (BOOL)renameCollidingFoldersInPackagesFolderBeforeImporting:(NSArray *)resourcePathsToImport error:(NSError **)error
{
    for (NSMutableString *resourcePath in resourcePathsToImport)
    {
        NSString *futurePackageName = [resourcePath lastPathComponent];
        NSString *futurePackagePath = [_projectSettings fullPathForPackageName:futurePackageName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:futurePackagePath])
        {
            NSString *newPath = [self rollingRenamedPathForPath:futurePackagePath suffix:@"renamed"];

            if (![self moveFileAndAddToCommandStackAtPath:futurePackagePath toPath:newPath error:error])
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

    for (NSMutableDictionary *resourcePathDict in [_projectSettings.resourcePaths copy])
    {
        NSString *fullResourcePath = [_projectSettings fullPathForResourcePathDict:resourcePathDict];
        if ([_projectSettings isPathInPackagesFolder:fullResourcePath])
        {
            continue;
        }

        [resourcePathsToImport addObject:[fullResourcePath mutableCopy]];
    }
    return resourcePathsToImport;
}

- (BOOL)removeResourcePathsToImportFromProject:(NSArray *)resourcePathsToImport error:(NSError **)error
{
    for (NSMutableString *resourcePath in resourcePathsToImport)
    {
        if (![_projectSettings removeResourcePath:resourcePath error:error])
        {
            return NO;
        }
    }
    return YES;
}

- (BOOL)appendPackageSuffixToResourcePathsToImport:(NSArray *)resourcePathsToImport error:(NSError **)error
{
    for (NSMutableString *fullPath in resourcePathsToImport)
    {
        if (![fullPath hasPackageSuffix])
        {
            NSString *oldPath = fullPath;
            NSString *newPath = [fullPath stringByAppendingPackageSuffix];

            if (![self moveFileAndAddToCommandStackAtPath:oldPath toPath:newPath error:error])
            {
                return NO;
            }

            [fullPath setString:newPath];
        }
    }
    return YES;
}

- (BOOL)importAndDeleteOldResourcePathsToImport:(NSArray *)resourcePathsToImport error:(NSError **)error
{
    for (NSString *pathToImport in resourcePathsToImport)
    {
        PackageImporter *packageImporter = [[PackageImporter alloc] init];
        packageImporter.projectSettings = _projectSettings;

        if ([packageImporter importPackagesWithPaths:@[pathToImport] error:error])
        {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager removeItemAtPath:pathToImport error:error])
            {
                return NO;
            }
        }
        else
        {
            return NO;
        }
    }
    return YES;
}

- (BOOL)restoreCollidingResourcePathName:(NSError **)error
{
    if (_resourcePathWithPackagesFolderNameFound)
    {
        PackageRenamer *packageRenamer = [[PackageRenamer alloc] init];
        packageRenamer.projectSettings = _projectSettings;
        packageRenamer.resourceManager = [ResourceManager sharedManager];

        RMPackage *package = [[RMPackage alloc] init];
        package.dirPath = [_projectSettings fullPathForPackageName:_packageAsResourcePathTempName];

        return [packageRenamer renamePackage:package toName:PACKAGES_FOLDER_NAME error:error];
    }
}

- (BOOL)createPackagesFolderIfNotExisting:(NSError **)error
{
    if ([self packageFolderExists])
    {
        LocalLogDebug(@"Creating packages folder...already exists.");
        return YES;
    }

    return [self tryToCreatePackagesFolder:error];
}

- (BOOL)tryToCreatePackagesFolder:(NSError **)error
{
    LocalLogDebug(@"Trying to create packages folder...");
    NSString *packageFolderPath = [_projectSettings packagesFolderPath];

    NSAssert(packageFolderPath, @"ProjectSettings' packagesFolderPath not yielding anything, forgot to set projectsettings.projectPath property?");

    CreateDirectoryFileCommand *createDirectoryFileCommand = [[CreateDirectoryFileCommand alloc] initWithDirPath:packageFolderPath];

    return [self executeCommandAndAddToStackOnSuccess:createDirectoryFileCommand error:error];
}

- (BOOL)packageFolderExists
{
    NSString *packageFolderPath = [_projectSettings packagesFolderPath];

    return [[NSFileManager defaultManager] fileExistsAtPath:packageFolderPath];
}

- (BOOL)renameResourcePathCollidingWithPackagesFolderName:(NSError **)error
{
    if ([self packageFolderExists]
        && [self isPackageFolderAResourcePath])
    {
        return [self renamePackagesResourcePathFolder:error];
    }
    return YES;
}

- (BOOL)isPackageFolderAResourcePath
{
    // NOTE: If a resource path is named packages/ or whatever in PACKAGES_FOLDER_NAME is
    // it has to be renamed in order create the packages/ folder
    if ([_projectSettings isResourcePathInProject:[_projectSettings packagesFolderPath]])
    {
        self.resourcePathWithPackagesFolderNameFound = YES;
        return YES;
    }
    return NO;
}

- (BOOL)renamePackagesResourcePathFolder:(NSError **)error
{
    LocalLogDebug(@"Trying to rename resource folder with \"packages\" name...");

    NSString *renamePathTo = [self renamePathForSpecialCasePackagesFolderAsResourcePath];
    self.packageAsResourcePathTempName = [renamePathTo lastPathComponent];

    NSString *renamePathFrom = [_projectSettings packagesFolderPath];
    if (![self moveFileAndAddToCommandStackAtPath:renamePathFrom toPath:renamePathTo error:error])
    {
        LocalLogError(@"ERROR Special case renaming: %@ -> \"%@\" found: renaming to: \"%@\"", (*error).localizedDescription, renamePathFrom, renamePathTo);
        return NO;
    }

    LocalLogDebug(@"Special case: resource path with name \"%@\" found: renaming to: \"%@\"", PACKAGES_FOLDER_NAME, renamePathTo);
    LocalLogDebug(@"Trying to rename resource folder with \"packages\" name DONE");

    NSString *newResourcePathName = [renamePathTo lastPathComponent];
    for (NSMutableDictionary *resourcePath in _projectSettings.resourcePaths)
    {
        if ([[_projectSettings fullPathForResourcePathDict:resourcePath] isEqualToString:[_projectSettings packagesFolderPath]])
        {
            // TODO: use ResourcePath object
            resourcePath[@"path"] = [[resourcePath[@"path"] stringByDeletingLastPathComponent] stringByAppendingPathComponent:newResourcePathName];
            LocalLogDebug(@"New relative path: \"%@\"", [_projectSettings fullPathForResourcePathDict:resourcePath]);
        }
    }

    return YES;
}

- (NSString *)renamePathForSpecialCasePackagesFolderAsResourcePath
{
    return [self rollingRenamedPathForPath:[_projectSettings packagesFolderPath] suffix:@"user"];
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

- (BOOL)moveFileAndAddToCommandStackAtPath:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error
{
    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:fromPath toPath:toPath];
    return [self executeCommandAndAddToStackOnSuccess:moveFileCommand error:error];
}

- (BOOL)executeCommandAndAddToStackOnSuccess:(id<FileCommandProtocol>)command error:(NSError **)error;
{
    BOOL success = [command execute:error];
    if (success)
    {
        [_migrationCommandsStack addObject:command];
    }
    return success;
}

- (void)rollback
{
    [self logMigrationStep:@"#rollback ..."];

    [self rollbackResourcePathChanges];

    [self rollbackFileSystemChanges];
}

- (void)rollbackFileSystemChanges
{
    NSArray *reversedStack = [[_migrationCommandsStack reverseObjectEnumerator] allObjects];
    for (id<FileCommandProtocol> command in reversedStack)
    {
        [self logMigrationStep:@"#rollback #Filesystem Undoing %@", command];
        NSError *error;
        if (![command undo:&error])
        {
            [self logMigrationStep:@"#rollback #Filesystem #error Undoing %@ - %@", command, error];
        }
    }
}

- (void)rollbackResourcePathChanges
{
    _projectSettings.resourcePaths = [_resourePathsBackup copy];
}

- (void)logMigrationStep:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    // #if TEST_TARGET != 0
    NSLogv([NSString stringWithFormat:@"%@ %@", PACKAGES_LOG_HASHTAG, format], args);
    // #endif
    va_end(args);
}

@end