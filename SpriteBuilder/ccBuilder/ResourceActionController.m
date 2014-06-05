#import <MacTypes.h>
#import "ResourceActionController.h"
#import "RMPackage.h"
#import "PackageCreateDelegateProtocol.h"
#import "PackageController.h"
#import "AppDelegate.h"
#import "ResourceMenuItem.h"
#import "ProjectSettings.h"
#import "RMResource.h"
#import "ResourceTypes.h"
#import "FeatureToggle.h"
#import "ResourceManager.h"
#import "NotificationNames.h"
#import "SequencerUtil.h"
#import "NewDocWindowController.h"
#import "ResolutionSetting.h"
#import "CocosScene.h"
#import "NotesLayer.h"
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

// TODO: temporary solution until automatic wiring can be done
- (ProjectSettings *)projectSettings
{
    return [AppDelegate appDelegate].projectSettings;
}

- (void)showResourceInFinder:(id)sender
{
    ResourceMenuItem *resourceMenuItem = sender;
    NSString *path = [self getPathOfResource:[resourceMenuItem.resources firstObject]];
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
    ResourceMenuItem *resourceMenuItem = sender;
    NSString *path = [self getPathOfResource:[resourceMenuItem.resources firstObject]];
    if (path)
    {
        [[NSWorkspace sharedWorkspace] openFile:path];
    }
}

- (void)toggleSmartSheet:(id)sender
{
    ResourceMenuItem *resourceMenuItem = sender;
    if (resourceMenuItem.resources.count == 0 || !self.projectSettings)
    {
        return;
    }

    id firstResource = [resourceMenuItem.resources objectAtIndex:0];

    RMResource *resource = (RMResource *) firstResource;
    RMDirectory *directory = resource.data;

    if (directory.isDynamicSpriteSheet)
    {
        [self.projectSettings removeSmartSpriteSheet:resource];
    }
    else
    {
        [self.projectSettings makeSmartSpriteSheet:resource];
    }
}

- (void)createKeyFrameFromSelection:(id)sender
{
    [SequencerUtil createFramesFromSelectedResources];
}

- (void)newFile:(id)sender
{
    ResourceMenuItem *resourceMenuItem = sender;

    [self newFileWithResource:[resourceMenuItem.resources firstObject] outlineView:nil];
}

- (void)newFileWithResource:(id)resource outlineView:(NSOutlineView *)outlineView
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
        NSString *dirPath = [self dirPathWithFirstDirFallbackForResource:resource];
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
                               [outlineView expandItem:parentResource];
                           });
        }
    }
}

- (void)newFolder:(id)sender
{
    ResourceMenuItem *resourceMenuItem = sender;

    // TODO: add outlineview to properties in here or update differently to put new folder into edit mode
    [self newFolderWithResource:[resourceMenuItem.resources firstObject] outlineView:nil];
}

- (void)newFolderWithResource:(id)resource outlineView:(NSOutlineView *)outlineView
{
    NSString *dirPath = [self dirPathWithFirstDirFallbackForResource:resource];
    if (!dirPath)
    {
        return;
    }

    NSString *newDirPath = [self newUntitledFolderInDirPath:dirPath];

    if (outlineView)
    {
        [self selectAndMakeFolderEditable:dirPath newDirPath:newDirPath outlineView:outlineView];
    }
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

- (void)selectAndMakeFolderEditable:(NSString *)dirPath newDirPath:(NSString *)newDirPath outlineView:(NSOutlineView *)outlineView
{
    RMResource *newResource = [[ResourceManager sharedManager] resourceForPath:newDirPath];

    id parentResource = [[ResourceManager sharedManager] resourceForPath:dirPath];
    [outlineView expandItem:parentResource];
    [outlineView editColumn:0 row:[outlineView rowForItem:newResource] withEvent:nil select:YES];
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
    ResourceMenuItem *resourceMenuItem = sender;
    [self deleteResources:resourceMenuItem.resources];
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

    // TODO: this can all be moved to the resource manager
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

    // TODO: move to reloadAllResources?
    [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCES_CHANGED object:nil];

    [[ResourceManager sharedManager] reloadAllResources];
}


#pragma mark - Export packages

- (void)exportPackage:(id)sender
{
    ResourceMenuItem *resourceMenuItem = sender;
    id firstResource = [resourceMenuItem.resources objectAtIndex:0];

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
                             informativeTextWithFormat:error.localizedDescription];
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