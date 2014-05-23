#import "PackageCreateDelegateProtocol.h"
#import "PackageController.h"
#import "NewPackageWindowController.h"
#import "ProjectSettings.h"
#import "SnapLayerKeys.h"
#import "SBErrors.h"
#import "MiscConstants.h"


@implementation PackageController

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
    NSAssert(_projectSettings != nil, @"No ProjectSettings injected.");

    if ([_projectSettings addResourcePath:packagePath error:error])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
        return YES;
    }

    return NO;
}

- (BOOL)removePackagesFromProject:(NSArray *)packagePaths error:(NSError **)error
{
    if (!packagePaths)
    {
        return YES;
    }

    // TODO: error checking?
    for (NSString *packagePath in packagePaths)
    {
        [_projectSettings removeResourcePath:packagePath];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
}

- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPath = [self fullPathForPackageName:packageName];

    if ([_projectSettings isResourcePathAlreadyInProject:fullPath])
    {
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:SBDuplicateResourcePathError
                                 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Package %@ already in project", packageName]}];
        return NO;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:NO attributes:nil error:error]
        && [_projectSettings addResourcePath:fullPath error:error])
    {
        [self addIconToPackageFile:fullPath];

        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
        return YES;
    }
    return NO;
}

@end