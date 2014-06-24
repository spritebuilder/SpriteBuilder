#import "PackageMigrator.h"

#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"
#import "MiscConstants.h"

#define LocalLogDebug( s, ... ) NSLog( @"[DEBUG] <%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#define LocalLogError( s, ... ) NSLog( @"[ERROR] <%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )

@interface PackageMigrator ()

@property (nonatomic, strong) NSMutableDictionary *renameMap;
@property (nonatomic, weak)ProjectSettings *projectSettings;
@property (nonatomic) BOOL resourcePathWithPackagesFolderNameFound;

@end


@implementation PackageMigrator

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    self = [super init];
    if (self)
    {
        self.projectSettings = projectSettings;
        self.resourcePathWithPackagesFolderNameFound = NO;
        self.renameMap = [NSMutableDictionary dictionary];
    }

    return self;
}

- (BOOL)migrate:(NSError **)error
{
    LocalLogDebug(@"Package migration started...");

    if (![self renameResourcePathWithPackagesFolderName:error])
    {
        return NO;
    }

    if (![self createPackagesFolderIfNotExisting:NULL])
    {
        return NO;
    }

    if (![self migrateAllResourcePaths:error])
    {
        return NO;
    }

    LocalLogDebug(@"Package finished successfully!");
    return YES;
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

- (BOOL)renameResourcePathWithPackagesFolderName:(NSError **)error
{
    if ([self packageFolderExists]
        && [self isPackageFolderAResourcePath])
    {
        return [self renamePackagesResourcePathFolder:error];
    }
    return YES;
}

- (BOOL)packageFolderExists
{
    NSString *packageFolderPath = [_projectSettings packagesFolderPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    return [fileManager fileExistsAtPath:packageFolderPath];
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
    NSString *renamePathTo = [self renamePathForSpecialCasePackagesFolderAsResourcePath:@"user"];

    NSString *renamePathFrom = [_projectSettings packagesFolderPath];
    if (![fileManager moveItemAtPath:renamePathFrom toPath:renamePathTo error:error])
    {
        LocalLogError(@"ERROR Special case renaming: %@ -> \"%@\" found: renaming to: \"%@\"", (*error).localizedDescription, renamePathFrom, renamePathTo);
        return NO;
    }

    _renameMap[renamePathFrom] = renamePathTo;

    LocalLogDebug(@"Special case: resource path with name \"%@\" found: renaming to: \"%@\"", PACKAGES_FOLDER_NAME, renamePathTo);
    LocalLogDebug(@"Trying to rename resource folder with \"packages\" name DONE");

    return YES;
}

- (NSString *)renamePathForSpecialCasePackagesFolderAsResourcePath:(NSString *)suffix
{
    NSFileManager *fileManager = [NSFileManager defaultManager];;
    NSString *renamePathTo = [[_projectSettings packagesFolderPath] stringByAppendingPathExtension:suffix];
    NSUInteger count = 0;
    while ([fileManager fileExistsAtPath:renamePathTo])
    {
        LocalLogDebug(@"Special case: name \"%@\" exists, trying next...", [renamePathTo lastPathComponent]);

        NSString *renameSuffixWithCount =[NSString stringWithFormat:@"%@.%lu", suffix, count];
        renamePathTo = [[_projectSettings packagesFolderPath] stringByAppendingPathExtension:renameSuffixWithCount];
        count ++;
    }
    return renamePathTo;
}

- (BOOL)migrateAllResourcePaths:(NSError **)error
{
    LocalLogDebug(@"Migrating resource paths...");
    for (NSMutableDictionary *resourcePath in _projectSettings.resourcePaths)
    {
        LocalLogDebug(@"Current resource path %@", resourcePath[@"path"]);



    }
}

- (BOOL)isResourcePathInPackagesFolder:(NSMutableDictionary *)resourcePath
{

}

- (BOOL)renameResourcePathBeforeMovingToPackage:(NSMutableDictionary *)resourcePath
{
    // Use map?
}

- (BOOL)moveResourcePathToPackagesFolder:(NSString *)resourcePath
{

}

- (BOOL)restoreSpecialCasePackagesResourcePathFolder
{
    // The renamed resource path has been moved and can now be renamed back to
    // its original name, it will get the PACKAGE_NAME_SUFFIX appended later on
    if (_resourcePathWithPackagesFolderNameFound)
    {
        // Restore name
    }
}

- (BOOL)addPackageSuffixToMovedResourcePaths:(NSMutableDictionary *)resourcePath
{

}



@end