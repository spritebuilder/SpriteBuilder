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
#import "RemoveFileCommand.h"
#import "NSError+SBErrors.h"
#import "SBErrors.h"
#import "NSAlert+Convenience.h"


NSString *const PACKAGES_LOG_HASHTAG = @"#packagemigration";


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
    if (![self needsMigration])
    {
        return YES;
    }

    [self logMigrationStep:@"Starting..."];

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

    [self logMigrationStep:@"successful!"];
    return YES;
}

- (NSError *)standardError
{
    NSString *message = [NSString stringWithFormat:@
            "Migration of project to new packages structure failed. "
            "<b>The different migration steps have been rolled back.</b><br/><br/> "
            "The project will be opened as usual, however you can help us by creating an <a href=\"https://github.com/spritebuilder/SpriteBuilder/issues/new\">issue on github</a> and posting the content of the log, see below. "
            "You can use the <a href=\"file:///Applications/Utilities/Console.app\">Console app</a> to view the system log. "
            "Search for <b>%@.</b><br/><br/> "
            "There is more information about package migration on the <a href=\"%@\">forums.</a> "
            , @"link", PACKAGES_LOG_HASHTAG];

    return [NSError errorWithDomain:SBErrorDomain
                               code:SBMigrationError
                           userInfo:@{NSLocalizedDescriptionKey : message}];
}

- (BOOL)needsMigration
{
    for (NSMutableDictionary *dict in _projectSettings.resourcePaths)
    {
        NSString *fullPath = [_projectSettings fullPathForResourcePathDict:dict];

        if (![fullPath hasPackageSuffix]
            || ![_projectSettings isPathInPackagesFolder:fullPath])
        {
            return YES;
        }
    }
    return NO;
}

- (void)backupResourcePaths
{
    [_resourePathsBackup removeAllObjects];
    for (NSMutableDictionary *resourcePath in _projectSettings.resourcePaths)
    {
        [_resourePathsBackup addObject:[resourcePath copy]];
    }
}

- (BOOL)renameCollidingFoldersInPackagesFolderBeforeImporting:(NSArray *)resourcePathsToImport
{
    for (NSMutableString *resourcePath in resourcePathsToImport)
    {
        NSString *futurePackageName = [resourcePath lastPathComponent];
        NSString *futurePackagePath = [_projectSettings fullPathForPackageName:futurePackageName];
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

- (BOOL)removeResourcePathsToImportFromProject:(NSArray *)resourcePathsToImport
{
    for (NSMutableString *resourcePath in resourcePathsToImport)
    {
        NSError *error;
        if (![_projectSettings removeResourcePath:resourcePath error:&error])
        {
            [self logMigrationStep:@"#error removing resource path %@ - %@", resourcePath, error.localizedDescription];
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
        packageImporter.projectSettings = _projectSettings;

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
            [self logMigrationStep:@"#error Package importing \"%@\" failed: %@", pathToImport, error.localizedDescription];
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
        packageRenamer.projectSettings = _projectSettings;
        packageRenamer.resourceManager = [ResourceManager sharedManager];

        RMPackage *package = [[RMPackage alloc] init];
        package.dirPath = [_projectSettings fullPathForPackageName:_packageAsResourcePathTempName];

        NSError *error;
        BOOL success = [packageRenamer renamePackage:package toName:PACKAGES_FOLDER_NAME error:&error];
        if (!success)
        {
            [self logMigrationStep:@"#error Package renaming failed: %@", error.localizedDescription];
        }

        return success;
    }
    return YES;
}

- (BOOL)createPackagesFolderIfNotExisting
{
    if ([self packageFolderExists])
    {
        return YES;
    }

    return [self tryToCreatePackagesFolder];
}

- (BOOL)tryToCreatePackagesFolder
{
    NSString *packageFolderPath = [_projectSettings packagesFolderPath];

    NSAssert(packageFolderPath, @"ProjectSettings' packagesFolderPath not yielding anything, forgot to set projectsettings.projectPath property?");

    CreateDirectoryFileCommand *createDirectoryFileCommand = [[CreateDirectoryFileCommand alloc] initWithDirPath:packageFolderPath];

    return [self executeCommandAndAddToStackOnSuccess:createDirectoryFileCommand];
}

- (BOOL)packageFolderExists
{
    NSString *packageFolderPath = [_projectSettings packagesFolderPath];

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
    if ([_projectSettings isResourcePathInProject:[_projectSettings packagesFolderPath]])
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

    NSString *renamePathFrom = [_projectSettings packagesFolderPath];
    if (![self moveFileAndAddToCommandStackAtPath:renamePathFrom toPath:renamePathTo])
    {
        return NO;
    }

    NSString *newResourcePathName = [renamePathTo lastPathComponent];
    for (NSMutableDictionary *resourcePath in _projectSettings.resourcePaths)
    {
        if ([[_projectSettings fullPathForResourcePathDict:resourcePath] isEqualToString:[_projectSettings packagesFolderPath]])
        {
            // TODO: use ResourcePath object
            resourcePath[@"path"] = [[resourcePath[@"path"] stringByDeletingLastPathComponent] stringByAppendingPathComponent:newResourcePathName];
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

- (BOOL)moveFileAndAddToCommandStackAtPath:(NSString *)fromPath toPath:(NSString *)toPath
{
    MoveFileCommand *moveFileCommand = [[MoveFileCommand alloc] initWithFromPath:fromPath toPath:toPath];

    return [self executeCommandAndAddToStackOnSuccess:moveFileCommand];
}

- (BOOL)executeCommandAndAddToStackOnSuccess:(id <FileCommandProtocol>)command
{
    [self logMigrationStep:@"#Filesystem %@", [command description]];

    NSError *error;
    BOOL success = [command execute:&error];
    if (success)
    {
        [_migrationCommandsStack addObject:command];
    }
    else
    {
        [self logMigrationStep:@"#error %@ - %@", [command description], error.localizedDescription];
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
    #ifndef TESTING
    NSLogv([NSString stringWithFormat:@"%@ %@", PACKAGES_LOG_HASHTAG, format], args);
    #endif
    va_end(args);
}

@end