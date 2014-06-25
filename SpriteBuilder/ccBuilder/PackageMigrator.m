#import "PackageMigrator.h"

#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"
#import "NSString+Packages.h"
#import "PackageImporter.h"
#import "MiscConstants.h"
#import "PackageRenamer.h"
#import "ResourceManager.h"
#import "RMPackage.h"

#define LocalLogDebug( s, ... ) NSLog( @"[DEBUG] <%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#define LocalLogError( s, ... ) NSLog( @"[ERROR] <%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )

@interface PackageMigrator ()

@property (nonatomic, weak)ProjectSettings *projectSettings;
@property (nonatomic) BOOL resourcePathWithPackagesFolderNameFound;
@property (nonatomic, copy) NSString *packageAsResourcePathTempName;

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
    }

    return self;
}

- (BOOL)migrate:(NSError **)error
{
    LocalLogDebug(@"Package migration started...");

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

    [self restoreCollidingResourcePathName];

    LocalLogDebug(@"Package finished successfully!");
    return YES;
}

- (BOOL)renameCollidingFoldersInPackagesFolderBeforeImporting:(NSArray *)resourcePathsToImport error:(NSError **)error
{
    for (NSMutableString *resourcePath in resourcePathsToImport)
    {
        NSString *futurePackageName = [resourcePath lastPathComponent];
        NSString *futurePackagePath = [_projectSettings fullPathForPackageName:futurePackageName];
        NSFileManager *fileManager = [NSFileManager defaultManager];;
        if ([fileManager fileExistsAtPath:futurePackagePath])
        {
            NSString *newPath = [self rollingRenamedPathForPath:futurePackagePath suffix:@"renamed"];
            if (![fileManager moveItemAtPath:futurePackagePath toPath:newPath error:error])
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

            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager moveItemAtPath:oldPath toPath:newPath error:error])
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

- (void)restoreCollidingResourcePathName
{
    if (_resourcePathWithPackagesFolderNameFound)
    {
        PackageRenamer *packageRenamer = [[PackageRenamer alloc] init];
        packageRenamer.projectSettings = _projectSettings;
        packageRenamer.resourceManager = [ResourceManager sharedManager];

        RMPackage *package = [[RMPackage alloc] init];
        package.dirPath = [_projectSettings fullPathForPackageName:_packageAsResourcePathTempName];

        [packageRenamer renamePackage:package toName:PACKAGES_FOLDER_NAME error:nil];
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

    NSFileManager *fileManager = [NSFileManager defaultManager];;
    if (![fileManager createDirectoryAtPath:packageFolderPath
                          withIntermediateDirectories:NO
                                           attributes:nil
                                                error:error])
    {
        LocalLogError(@"ERROR Creating packages folder: %@", (*error).localizedDescription);
        return NO;
    }

    LocalLogDebug(@"Trying to create packages folder DONE");
    return YES;
}

- (BOOL)packageFolderExists
{
    NSString *packageFolderPath = [_projectSettings packagesFolderPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    return [fileManager fileExistsAtPath:packageFolderPath];
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

    NSFileManager *fileManager = [NSFileManager defaultManager];;
    NSString *renamePathTo = [self renamePathForSpecialCasePackagesFolderAsResourcePath];
    self.packageAsResourcePathTempName = [renamePathTo lastPathComponent];

    NSString *renamePathFrom = [_projectSettings packagesFolderPath];
    if (![fileManager moveItemAtPath:renamePathFrom toPath:renamePathTo error:error])
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
    NSFileManager *fileManager = [NSFileManager defaultManager];;
    NSUInteger count = 0;

    while ([fileManager fileExistsAtPath:result])
    {
        NSString *renameSuffixWithCount = [NSString stringWithFormat:@"%@.%lu", suffix, count];
        result = [originalPath stringByAppendingPathExtension:renameSuffixWithCount];
        count ++;
    }
    return result;
}

@end