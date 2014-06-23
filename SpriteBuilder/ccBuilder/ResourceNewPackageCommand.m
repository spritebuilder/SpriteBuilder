#import "ResourceCommandProtocol.h"

#import "ResourceNewPackageCommand.h"
#import "ProjectSettings.h"
#import "PackageCreator.h"
#import "NewPackageWindowController.h"

@implementation ResourceNewPackageCommand

- (void)execute
{
    NSAssert(_windowForModals != nil, @"windowForModals must no be nil, modal sheet can't be attached.");

    PackageCreator *packageCreator = [[PackageCreator alloc] init];
    packageCreator.projectSettings = _projectSettings;

    NewPackageWindowController *packageWindowController = [[NewPackageWindowController alloc] init];
    packageWindowController.packageCreator = packageCreator;

    // Show new document sheet
    [NSApp beginSheet:[packageWindowController window]
       modalForWindow:_windowForModals
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];

    [NSApp runModalForWindow:[packageWindowController window]];
    [NSApp endSheet:[packageWindowController window]];
    [[packageWindowController window] close];
}


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"New Package...";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return resources.count == 0;
}


@end