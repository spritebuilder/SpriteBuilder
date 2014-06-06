#import "ResourceNewFileCommand.h"

#import "AppDelegate.h"
#import "NewDocWindowController.h"
#import "NSAlert+Convenience.h"
#import "ResourceManager.h"
#import "RMDirectory.h"
#import "RMResource.h"
#import "ResourceTypes.h"


@implementation ResourceNewFileCommand

- (void)execute
{
    NSAssert(_windowForModals != nil, @"windowForModals must no be nil, modal sheet can't be attached.");

    NewDocWindowController *newFileWindowController = [[NewDocWindowController alloc] initWithWindowNibName:@"NewDocWindow"];

    [NSApp beginSheet:[newFileWindowController window]
       modalForWindow:_windowForModals
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];

    int acceptedModal = (int)[NSApp runModalForWindow:[newFileWindowController window]];
    [NSApp endSheet:[newFileWindowController window]];
    [[newFileWindowController window] close];

    if (acceptedModal)
    {
        NSString *dirPath = [self dirPathWithFirstDirFallbackForResource:_resources.firstObject];
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
                           dispatch_get_current_queue(), ^
                    {
                        [[AppDelegate appDelegate] newFile:filePath type:type resolutions:resolutions];

                        id parentResource = [[ResourceManager sharedManager] resourceForPath:dirPath];
                        [_outlineView expandItem:parentResource];
                    });
        }
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


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"New File...";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return YES;
}

@end