#import "ResourceExportPackageCommand.h"

#import "AppDelegate.h"
#import "RMPackage.h"
#import "PackageController.h"


@implementation ResourceExportPackageCommand

- (void)execute
{
    id firstResource = _resources.firstObject;

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


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"Export to...";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return ([resources.firstObject isKindOfClass:[RMPackage class]]);
}

@end