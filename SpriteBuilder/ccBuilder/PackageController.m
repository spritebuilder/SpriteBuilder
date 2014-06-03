#import <MacTypes.h>
#import "PackageCreateDelegateProtocol.h"
#import "PackageController.h"
#import "NewPackageWindowController.h"
#import "ProjectSettings.h"
#import "SnapLayerKeys.h"
#import "SBErrors.h"
#import "MiscConstants.h"
#import "Package.h"


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
    NSString *fullPackageName = [NSString stringWithFormat:@"%@.%@", packageName, PACKAGE_NAME_SUFFIX];
    return [_projectSettings.projectPathDir stringByAppendingPathComponent:fullPackageName];
}


# pragma mark - PackageCreateDelegate

- (BOOL)importPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPath = [self fullPathForPackageName:packageName];
    return [self importPackageWithPath:fullPath error:error];
}

- (BOOL)importPackageWithPath:(NSString *)packagePath error:(NSError **)error
{
    return [self importPackagesWithPaths:@[packagePath] error:error];
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
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:prevailingErrorCode
                                 userInfo:@{NSLocalizedDescriptionKey : errorDescription, @"errors" : errors}];
    }

    if (packagesAltered > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
    }

    return result;
}

- (BOOL)importPackagesWithPaths:(NSArray *)packagePaths error:(NSError **)error
{
    PackageManipulationBlock block = ^BOOL(NSString *packagePath, NSError **localError)
    {
        return [_projectSettings addResourcePath:packagePath error:localError];
    };

    return [self applyProjectSettingBlockForPackagePaths:packagePaths
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
        *error = [self duplicatePackageError:packageName];
        return NO;
    }

    NSError *underlyingErrorCreate;
    BOOL createDirSuccess = [_fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:NO attributes:nil error:&underlyingErrorCreate];
    if (!createDirSuccess && underlyingErrorCreate.code == NSFileWriteFileExistsError)
    {
        *error = [self packageExistsButNotInProjectError:packageName];
        return NO;
    }
    else if (!createDirSuccess)
    {
        *error = underlyingErrorCreate;
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

    *error = underlyingErrorAddResPath;
    return NO;
}

- (NSError *)packageExistsButNotInProjectError:(NSString *)packageName
{
    return [NSError errorWithDomain:SBErrorDomain
                               code:SBResourcePathExistsButNotInProjectError
                           userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Package %@ already in project", packageName]}];
}

- (NSError *)duplicatePackageError:(NSString *)packageName
{
    return [NSError errorWithDomain:SBErrorDomain
                               code:SBDuplicateResourcePathError
                           userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Package %@ already in project", packageName]}];
}

- (BOOL)exportPackage:(Package *)package toPath:(NSString *)toPath error:(NSError **)error
{
    if (!package || ![package isKindOfClass:[Package class]])
    {
        *error = [NSError errorWithDomain:SBErrorDomain code:SBPackageExportInvalidPackageError userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Internal error: Invalid package %@ given.", package]}];
        return NO;
    }
    
    if ([_fileManager fileExistsAtPath:toPath])
    {
        *error = [NSError errorWithDomain:SBErrorDomain code:SBPackageAlreadyExistsAtPathError userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Package already exists at path %@.", toPath]}];
        return NO;
    }

    return [_fileManager copyItemAtPath:package.path toPath:toPath error:error];
}

@end