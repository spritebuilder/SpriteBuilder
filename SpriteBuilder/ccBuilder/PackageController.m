#import <MacTypes.h>
#import "PackageCreateDelegateProtocol.h"
#import "PackageController.h"
#import "NewPackageWindowController.h"
#import "ProjectSettings.h"
#import "SnapLayerKeys.h"
#import "SBErrors.h"
#import "MiscConstants.h"


@implementation PackageController

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

- (BOOL)importPackagesWithPaths:(NSArray *)packagePaths error:(NSError **)error
{
    NSAssert(_projectSettings != nil, @"No ProjectSettings injected.");

    if (!packagePaths || packagePaths.count <= 0)
    {
        return YES;
    }

    BOOL result = YES;
    NSUInteger packagesAdded = 0;
    NSMutableArray *errors = [NSMutableArray array];

    for (NSString *packagePath in packagePaths)
    {
        NSError *anError;
        if (![_projectSettings addResourcePath:packagePath error:&anError])
        {
            [errors addObject:anError];
            result = NO;
        }
        else
        {
            packagesAdded++;
        }
    }

    if (errors.count > 0)
    {
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:SBImportingPackagesError
                                 userInfo:@{NSLocalizedDescriptionKey : @"One or more packages could not be added.", @"errors" : errors}];
    }

    if (packagesAdded > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
    }

    return result;
}

- (BOOL)removePackagesFromProject:(NSArray *)packagePaths error:(NSError **)error
{
    NSAssert(_projectSettings != nil, @"No ProjectSettings injected.");

    if (!packagePaths || packagePaths.count <= 0)
    {
        return YES;
    }

    BOOL result = YES;
    NSUInteger packagesRemoved = 0;
    NSMutableArray *errors = [NSMutableArray array];

    for (NSString *packagePath in packagePaths)
    {
        NSError *anError;
        if (![_projectSettings removeResourcePath:packagePath error:&anError])
        {
            [errors addObject:anError];
            result = NO;
        }
        else
        {
            packagesRemoved++;
        }
    }

    if (errors.count > 0)
    {
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:SBRemovePackagesError
                                 userInfo:@{NSLocalizedDescriptionKey : @"One or more packages could not be removed.", @"errors" : errors}];
    }

    if (packagesRemoved > 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
    }

    return result;
}

- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPath = [self fullPathForPackageName:packageName];

    if ([_projectSettings isResourcePathAlreadyInProject:fullPath])
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

@end