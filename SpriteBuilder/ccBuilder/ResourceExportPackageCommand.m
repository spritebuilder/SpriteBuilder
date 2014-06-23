#import "ResourceExportPackageCommand.h"

#import "RMPackage.h"
#import "PackageExporter.h"
#import "ProjectSettings.h"


@implementation ResourceExportPackageCommand

- (void)execute
{
    NSAssert(_windowForModals != nil, @"windowForModals must no be nil, modal sheet can't be attached.");

    id firstResource = _resources.firstObject;

    // Export supports only one package at a time, sorry
    if ([firstResource isKindOfClass:[RMPackage class]])
    {
        NSOpenPanel *openPanel = [self exportPanel];

        [openPanel beginSheetModalForWindow:_windowForModals
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
    PackageExporter *packageExporter = [[PackageExporter alloc] init];

    NSError *error;
    if (![packageExporter exportPackage:package toPath:exportPath error:&error])
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