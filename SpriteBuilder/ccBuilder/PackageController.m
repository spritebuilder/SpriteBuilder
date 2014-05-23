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


# pragma mark - PackageCreateDelegate

- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPackageName = [NSString stringWithFormat:@"%@.%@", packageName, PACKAGE_NAME_SUFFIX];
    NSString *newPackagePath = [_projectSettings.projectPathDir stringByAppendingPathComponent:fullPackageName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([_projectSettings isResourcePathAlreadyInProject:newPackagePath])
    {
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:SBDuplicateResourcePathError
                                 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Package %@ already in project", packageName]}];
        return NO;
    }

    if([fileManager createDirectoryAtPath:newPackagePath withIntermediateDirectories:NO attributes:nil error:error]
        && [_projectSettings addResourcePath:newPackagePath error:error])
    {
        [self addIconToPackageFile:newPackagePath];

        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
        return YES;
    }
    return NO;
}

- (void)addIconToPackageFile:(NSString *)packagePath
{
    NSImage* folderIcon = [NSImage imageNamed:@"Package.icns"];
    [[NSWorkspace sharedWorkspace] setIcon:folderIcon forFile:packagePath options:0];
}

- (void)importPackage:(NSString *)packagePath
{
    NSAssert(_projectSettings != nil, @"No ProjectSettings injected.");

    NSError *error;
    if ([_projectSettings addResourcePath:packagePath error:&error])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
    }
    else
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error"
                                         defaultButton:@"Ok"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:error.localizedDescription];

        [alert runModal];
    }
}

- (void)removePackagesFromProject:(NSArray *)packagePaths
{
    if (!packagePaths)
    {
        return;
    }

    // TODO: error checking?
    for (NSString *packagePath in packagePaths)
    {
        [_projectSettings removeResourcePath:packagePath];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
}


@end