#import <MacTypes.h>
#import "PackageCreateDelegateProtocol.h"
#import "PackageController.h"
#import "NewPackageWindowController.h"
#import "ProjectSettings.h"
#import "SnapLayerKeys.h"
#import "SBErrors.h"
#import "MiscConstants.h"
#import "RMPackage.h"
#import "NSError+SBErrors.h"
#import "ResourceManager.h"
#import "NSString+Packages.h"


@implementation PackageController

typedef BOOL (^PackageManipulationBlock) (NSString *packagePath, NSError **error);

- (id)init
{
    self = [super init];
    if (self)
    {
        // default until we get some injection framework running
        self.fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (void)showCreateNewPackageDialogForWindow:(NSWindow *)window
{
    NewPackageWindowController *packageWindowController = [[NewPackageWindowController alloc] init];
    packageWindowController.delegate = self;

    // Show new document sheet
    [NSApp beginSheet:[packageWindowController window]
       modalForWindow:window
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];

    [NSApp runModalForWindow:[packageWindowController window]];
    [NSApp endSheet:[packageWindowController window]];
    [[packageWindowController window] close];
}

- (void)addIconToPackageFile:(NSString *)packagePath
{
    NSImage* folderIcon = [NSImage imageNamed:@"Package.icns"];
    [[NSWorkspace sharedWorkspace] setIcon:folderIcon forFile:packagePath options:0];
}

- (NSString *)fullPathForPackageName:(NSString *)packageName
{
    NSString *packagesFolderPath = [_projectSettings.projectPathDir stringByAppendingPathComponent:PACKAGES_FOLDER_NAME];

    return [packagesFolderPath stringByAppendingPathComponent:[packageName stringByAppendingPackageSuffix]];
}


# pragma mark - PackageCreateDelegate

- (BOOL)importPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPath = [self fullPathForPackageName:packageName];

    return [self importPackagesWithPaths:@[fullPath] error:nil];
}

- (BOOL)applyProjectSettingBlockForPackagePaths:(NSArray *)packagePaths
                                          error:(NSError **)error
                            prevailingErrorCode:(NSInteger)prevailingErrorCode
                               errorDescription:(NSString *)errorDescription
                                          block:(PackageManipulationBlock)block
{
    NSAssert(_projectSettings != nil, @"No ProjectSettings injected.");

    if (!packagePaths || packagePaths.count <= 0)
    {
        return YES;
    }

    BOOL result = YES;
    NSUInteger packagesAltered = 0;
    NSMutableArray *errors = [NSMutableArray array];

    for (NSString *packagePath in packagePaths)
    {
        NSError *anError;
        if (!block(packagePath, &anError))
        {
            [errors addObject:anError];
            result = NO;
        }
        else
        {
            packagesAltered++;
        }
    }

    if (errors.count > 0)
    {
        [NSError setNewErrorWithCode:error code:prevailingErrorCode userInfo:@{NSLocalizedDescriptionKey : errorDescription, @"errors" : errors}];
    }

    if (packagesAltered > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
    }

    return result;
}

- (NSArray *)allPackagesInPaths:(NSArray *)paths
{
    if (!paths)
    {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray array];
    for (NSString *path in paths)
    {
        if ([path hasPackageSuffix])
        {
            [result addObject:path];
        }
    }
    return result;
}

- (BOOL)importPackagesWithPaths:(NSArray *)packagePaths error:(NSError **)error
{
    NSArray *filteredPaths = [self allPackagesInPaths:packagePaths];

    PackageManipulationBlock block = ^BOOL(NSString *packagePath, NSError **localError)
    {
        return [_projectSettings addResourcePath:packagePath error:localError];
    };

    return [self applyProjectSettingBlockForPackagePaths:filteredPaths
                                                   error:error
                                     prevailingErrorCode:SBImportingPackagesError
                                        errorDescription:@"One or more packages could not be imported."
                                                   block:block];
}

- (BOOL)removePackagesFromProject:(NSArray *)packagePaths error:(NSError **)error
{
    PackageManipulationBlock block = ^BOOL(NSString *packagePath, NSError **localError)
    {
        return [_projectSettings removeResourcePath:packagePath error:localError];
    };

    return [self applyProjectSettingBlockForPackagePaths:packagePaths
                                                   error:error
                                     prevailingErrorCode:SBRemovePackagesError
                                        errorDescription:@"One or more packages could not be removed."
                                                   block:block];
}

- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPath = [self fullPathForPackageName:packageName];

    if ([_projectSettings isResourcePathInProject:fullPath])
    {
        [NSError setNewErrorWithCode:error code:SBDuplicateResourcePathError message:[NSString stringWithFormat:@"Package %@ already in project", packageName]];
        return NO;
    }

    NSError *underlyingErrorCreate;
    BOOL createDirSuccess = [_fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:NO attributes:nil error:&underlyingErrorCreate];
    if (!createDirSuccess
        && underlyingErrorCreate.code == NSFileWriteFileExistsError)
    {
        [NSError setNewErrorWithCode:error code:SBResourcePathExistsButNotInProjectError message:[NSString stringWithFormat:@"Package %@ already in project", packageName]];
        return NO;
    }
    else if (!createDirSuccess)
    {
        [NSError setError:error withError:underlyingErrorCreate];
        return NO;
    }

    NSError *underlyingErrorAddResPath;
    BOOL addResPathSuccess = [_projectSettings addResourcePath:fullPath error:&underlyingErrorAddResPath];
    if(addResPathSuccess)
    {
        [self addIconToPackageFile:fullPath];

        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
        return YES;
    }

    [NSError setError:error withError:underlyingErrorAddResPath];
    return NO;
}

- (BOOL)exportPackage:(RMPackage *)package toPath:(NSString *)toPath error:(NSError **)error
{
    if ([self isPackageValid:package])
    {
        [NSError setNewErrorWithCode:error code:SBPackageExportInvalidPackageError message:[NSString stringWithFormat:@"Internal error: Invalid package %@ given.", package]];
        return NO;
    }

    NSString *copyToPath = [toPath stringByAppendingPathComponent:[package.dirPath lastPathComponent]];

    if ([_fileManager fileExistsAtPath:copyToPath])
    {
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:SBPackageAlreadyExistsAtPathError
                                 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Package %@ already exists at path %@.", package, toPath]}];
        return NO;
    }

    return [_fileManager copyItemAtPath:package.dirPath toPath:copyToPath error:error];
}

- (BOOL)isPackageValid:(RMPackage *)package
{
    return !package
        || ![package isKindOfClass:[RMPackage class]]
        || !package.dirPath;
}

- (BOOL)renamePackage:(RMPackage *)package toName:(NSString *)newName error:(NSError **)error
{
    NSAssert(_projectSettings != nil, @"ProjectSetting must not be nil");
    NSAssert(_resourceManager != nil, @"ResourceManager must not be nil");

    NSString *newFullPath = [self fullPathForRenamedPackage:package toName:newName];

    if ([package.dirPath isEqualToString:newFullPath])
    {
        return YES;
    }

    BOOL renameSuccessful = ([self canRenamePackage:package toName:newName error:error]
                            && [_fileManager moveItemAtPath:package.dirPath toPath:newFullPath error:error]
                            && [_projectSettings moveResourcePathFrom:package.dirPath toPath:newFullPath error:error]);

    if (renameSuccessful)
    {
        [_resourceManager setActiveDirectoriesWithFullReset:[_projectSettings absoluteResourcePaths]];
        return YES;
    }

    if (!*error)
    {
        [NSError setNewErrorWithCode:error code:SBRenamePackageGenericError message:[NSString stringWithFormat:@"An unexpected error occured. Code %li", SBRenamePackageGenericError]];
    }
    return NO;
}

- (BOOL)canRenamePackage:(RMPackage *)package toName:(NSString *)newName error:(NSError **)error
{
    NSString *newFullPath = [self fullPathForRenamedPackage:package toName:newName];

    if ([newFullPath isEqualToString:package.dirPath])
    {
        return YES;
    }

    if ([_projectSettings isResourcePathInProject:newFullPath])
    {
        [NSError setNewErrorWithCode:error code:SBDuplicateResourcePathError message:@"A package with this name already exists in the project"];
        return NO;
    }

    if ([_fileManager fileExistsAtPath:newFullPath])
    {
        [NSError setNewErrorWithCode:error code:SBResourcePathExistsButNotInProjectError message:@"A package with this name already exists on the file system, but is not in the project."];
        return NO;
    }

    return YES;
}

- (NSString *)fullPathForRenamedPackage:(RMPackage *)package toName:(NSString *)newName
{
    return [[package.dirPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[newName stringByAppendingPackageSuffix]];
}

@end