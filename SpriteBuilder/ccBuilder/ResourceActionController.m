#import "ResourceActionController.h"

#import "RMPackage.h"
#import "PackageCreateDelegateProtocol.h"
#import "PackageController.h"
#import "AppDelegate.h"
#import "ResourceMenuItem.h"
#import "ProjectSettings.h"
#import "ResourceManagerOutlineView.h"
#import "RMResource.h"
#import "ResourceTypes.h"
#import "FeatureToggle.h"
#import "ResourceManager.h"
#import "NotificationNames.h"
#import "SequencerUtil.h"
#import "NewDocWindowController.h"
#import "NSAlert+Convenience.h"


@implementation ResourceActionController

#pragma mark - Initialization

+ (id)sharedController
{
    static ResourceActionController *sharedResourceActionController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedResourceActionController = [[self alloc] init];
    });
    return sharedResourceActionController;
}

- (NSArray *)selectedResources
{
    return _resourceManagerOutlineView.selectedResources;
}

- (void)showResourceInFinder:(id)sender
{
    NSString *path = [self getPathOfResource:[[self selectedResources] firstObject]];
    if (path)
    {
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
    }
}

// TODO: this could go into a base class of resources
- (NSString *)getPathOfResource:(id)resource
{
    if (!resource)
    {
        return nil;
    }

    NSString *fullPath;
    if ([resource isKindOfClass:[RMDirectory class]])
    {
        fullPath = ((RMDirectory *) resource).dirPath;
    }
    else if ([resource isKindOfClass:[RMResource class]])
    {
        fullPath = ((RMResource *) resource).filePath;
    }

    // if it doesn't exist, peek inside "resources-auto" (only needed in the case of resources, which has a different visual
    // layout than what is actually on the disk).
    // Should probably be removed and pulled into [RMResource filePath]
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath] == NO)
    {
        NSString *filename = [fullPath lastPathComponent];
        NSString *directory = [fullPath stringByDeletingLastPathComponent];
        fullPath = [NSString pathWithComponents:[NSArray arrayWithObjects:directory, @"resources-auto", filename, nil]];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath] == NO)
    {
        return nil;
    }

    return fullPath;
}

- (void)openResourceWithExternalEditor:(id)sender
{
    NSString *path = [self getPathOfResource:[[self selectedResources] firstObject]];
    if (path)
    {
        [[NSWorkspace sharedWorkspace] openFile:path];
    }
}

- (void)toggleSmartSheet:(id)sender
{
    if ([self selectedResources].count == 0 || !_projectSettings)
    {
        return;
    }

    RMResource *resource = (RMResource *) [self selectedResources].firstObject;
    RMDirectory *directory = resource.data;

    if (directory.isDynamicSpriteSheet)
    {
        [_projectSettings removeSmartSpriteSheet:resource];
    }
    else
    {
        [_projectSettings makeSmartSpriteSheet:resource];
    }
}

- (void)createKeyFrameFromSelection:(id)sender
{
    [SequencerUtil createFramesFromSelectedResources];
}

- (void)newFile:(id)sender
{
    NewDocWindowController *newFileWindowController = [[NewDocWindowController alloc] initWithWindowNibName:@"NewDocWindow"];

    [NSApp beginSheet:[newFileWindowController window]
       modalForWindow:[AppDelegate appDelegate].window
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];

    int acceptedModal = (int)[NSApp runModalForWindow:[newFileWindowController window]];
    [NSApp endSheet:[newFileWindowController window]];
    [[newFileWindowController window] close];

    if (acceptedModal)
    {
        NSString *dirPath = [self dirPathWithFirstDirFallbackForResource:[self selectedResources].firstObject];
        if (!dirPath)
        {
            return;
        }

        NSString* filePath = [dirPath stringByAppendingPathComponent:newFileWindowController.documentName];

        if (![[filePath pathExtension] isEqualToString:@"ccb"])
        {
            filePath = [filePath stringByAppendingPathExtension:@"ccb"];
        }

        BOOL isDir = NO;

        if (!newFileWindowController.documentName)
        {
            [NSAlert showModalDialogWithTitle:@"Missing File Name" message:@"Failed to create file, no file name was specified."];
        }
        else if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            [NSAlert showModalDialogWithTitle:@"File Already Exists" message:@"Failed to create file, a file with the same name already exists."];
        }
        else if (![[NSFileManager defaultManager] fileExistsAtPath:[filePath stringByDeletingLastPathComponent] isDirectory:&isDir] || !isDir)
        {
            [NSAlert showModalDialogWithTitle:@"Invalid Directory" message:@"Failed to create file, the directory for the file doesn't exist."];
        }
        else
        {
            int type = newFileWindowController.rootObjectType;
            NSMutableArray *resolutions = newFileWindowController.availableResolutions;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0),
                           dispatch_get_current_queue(), ^{
                               [[AppDelegate appDelegate] newFile:filePath type:type resolutions:resolutions];
                               id parentResource = [[ResourceManager sharedManager] resourceForPath:dirPath];
                               [_resourceManagerOutlineView expandItem:parentResource];
                           });
        }
    }
}

- (void)newFolder:(id)sender
{
    NSString *dirPath = [self dirPathWithFirstDirFallbackForResource:[self selectedResources].firstObject];
    if (!dirPath)
    {
        return;
    }

    NSString *newDirPath = [self newUntitledFolderInDirPath:dirPath];

    [self selectAndMakeFolderEditable:dirPath newDirPath:newDirPath];
}

- (NSString *)dirPathWithFirstDirFallbackForResource:(id)resource
{
    NSString *dirPath = [self dirPathForResource:resource];

    // Find directory
    NSArray *dirs = [ResourceManager sharedManager].activeDirectories;
    if (dirs.count == 0)
    {
        return nil;
    }

    RMDirectory *dir = [dirs objectAtIndex:0];
    if (!dirPath)
    {
        dirPath = dir.dirPath;
    }
    return dirPath;
}

- (NSString *)dirPathForResource:(id)resource
{
    NSString *dirPath;
    if ([resource isKindOfClass:[RMDirectory class]])
    {
        RMDirectory *directoryResource = (RMDirectory *) resource;
        dirPath = directoryResource.dirPath;

    }
    else if ([resource isKindOfClass:[RMResource class]])
    {
        RMResource *aResource = (RMResource *) resource;
        if (aResource.type == kCCBResTypeDirectory)
        {
            dirPath = aResource.filePath;
        }
        else
        {
            dirPath = [aResource.filePath stringByDeletingLastPathComponent];
        }
    }
    return dirPath;
}

- (void)selectAndMakeFolderEditable:(NSString *)dirPath newDirPath:(NSString *)newDirPath
{
    RMResource *newResource = [[ResourceManager sharedManager] resourceForPath:newDirPath];

    id parentResource = [[ResourceManager sharedManager] resourceForPath:dirPath];
    [_resourceManagerOutlineView expandItem:parentResource];
    [_resourceManagerOutlineView editColumn:0 row:[_resourceManagerOutlineView rowForItem:newResource] withEvent:nil select:YES];
}

- (NSString *)newUntitledFolderInDirPath:(NSString *)dirPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    int attempt = 0;
    NSString *newDirPath = NULL;
    while (newDirPath == NULL)
    {
        NSString *dirName = NULL;
        if (attempt == 0)
        {
            dirName = @"Untitled Folder";
        }
        else
        {
            dirName = [NSString stringWithFormat:@"Untitled Folder %d", attempt];
        }

        newDirPath = [dirPath stringByAppendingPathComponent:dirName];

        if ([fileManager fileExistsAtPath:newDirPath])
        {
            attempt++;
            newDirPath = NULL;
        }
    }

    // Create directory
    [fileManager createDirectoryAtPath:newDirPath withIntermediateDirectories:YES attributes:NULL error:NULL];
    [[ResourceManager sharedManager] reloadAllResources];

    return newDirPath;
}

- (void)deleteResource:(id)sender
{
    [self deleteResources:[self selectedResources]];
}

- (void)deleteResources:(NSArray *)resources
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you want to delete the selected files?"
                                     defaultButton:@"Cancel"
                                   alternateButton:@"Delete"
                                       otherButton:NULL
                         informativeTextWithFormat:@"You cannot undo this operation."];

    NSInteger result = [alert runModal];

    if (result == NSAlertDefaultReturn)
    {
        return;
    }

    NSMutableArray *resourcesToDelete = [[NSMutableArray alloc] init];
    NSMutableArray *foldersToDelete = [[NSMutableArray alloc] init];
    NSMutableArray *packagesPathsToDelete = [[NSMutableArray alloc] init];

    for (id resource in resources)
    {
        if ([resource isKindOfClass:[RMResource class]])
        {
            RMResource *aResource = (RMResource *) resource;
            if (aResource.type == kCCBResTypeDirectory)
            {
                [foldersToDelete addObject:resource];
            }
            else
            {
                [resourcesToDelete addObject:resource];
            }
        }
        else if ([resource isKindOfClass:[RMPackage class]]
                 && [FeatureToggle sharedFeatures].arePackagesEnabled)
        {
            RMPackage *rmDirectory = (RMPackage *) resource;
            [packagesPathsToDelete addObject:rmDirectory.dirPath];
        }
    }

    for (RMResource *res in resourcesToDelete)
    {
        [ResourceManager removeResource:res];
    }

    for (RMResource *res in foldersToDelete)
    {
        [ResourceManager removeResource:res];
    }

    PackageController *packageController = [[PackageController alloc] init];
    packageController.projectSettings = [AppDelegate appDelegate].projectSettings;
    [packageController removePackagesFromProject:packagesPathsToDelete error:NULL];

    [_resourceManagerOutlineView deselectAll:nil];

    [[ResourceManager sharedManager] reloadAllResources];
}


#pragma mark - Export packages

- (void)exportPackage:(id)sender
{
    id firstResource = [self selectedResources].firstObject;

    // Export supports only one package at a time, sorry
    if ([firstResource isKindOfClass:[RMPackage class]])
    {
        NSOpenPanel *openPanel = [self exportPanel];

        [openPanel beginSheetModalForWindow:[AppDelegate appDelegate].window
                          completionHandler:^(NSInteger result)
        {
            if (result == NSFileHandlingPanelOKButton)
            {
                [self tryToExportPackage:firstResource toPath:openPanel.directoryURL.path];
            }
        }];
    }
}

- (void)tryToExportPackage:(RMPackage *)package toPath:(NSString *)exportPath
{
    PackageController *packageController = [[PackageController alloc] init];
    NSError *error;

    if (![packageController exportPackage:package toPath:exportPath error:&error])
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", error.localizedDescription];
        [alert runModal];
    }
}

- (NSOpenPanel *)exportPanel
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [openPanel setCanCreateDirectories:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setPrompt:@"Export"];

    return openPanel;
}

@end