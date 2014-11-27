#import "ResourceNewFileCommand.h"

#import "AppDelegate.h"
#import "NewDocWindowController.h"
#import "NSAlert+Convenience.h"
#import "ResourceManager.h"
#import "RMResource.h"
#import "MiscConstants.h"


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
        NSString *dirPath = [_resourceManager dirPathWithFirstDirFallbackForResource:_resources.firstObject];
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

        if (![self isValidFilename:newFileWindowController.documentName])
        {
            [NSAlert showModalDialogWithTitle:@"Invalid File Name" message:@"Failed to create file, name was either invalid or missing."];
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
                           dispatch_get_main_queue(), ^
                    {
                        [[AppDelegate appDelegate] newFile:filePath type:type resolutions:resolutions];

                        id parentResource = [_resourceManager resourceForPath:dirPath];
                        [_outlineView expandItem:parentResource];
                    });
        }
    }
}

- (BOOL)isValidFilename:(NSString *)name
{
    BOOL isLongEnough;
    NSString *withoutFileExtension = [name stringByReplacingOccurrencesOfString:@".ccb" withString:@""];
    NSString *withoutWhitespace = [withoutFileExtension stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    isLongEnough = withoutWhitespace.length >= MINIMUM_FILENAME_LENGTH;

    BOOL firstCharIsDot = [[name substringWithRange:(NSRange) {.location = 0, .length = 1}] isEqualToString:@"."];

    return isLongEnough && !firstCharIsDot;
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