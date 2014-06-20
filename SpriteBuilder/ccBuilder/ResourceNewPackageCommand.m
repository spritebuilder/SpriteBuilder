#import "ResourceCommandProtocol.h"

#import "ResourceNewPackageCommand.h"
#import "ProjectSettings.h"
#import "PackageController.h"

@implementation ResourceNewPackageCommand

- (void)execute
{
    NSAssert(_windowForModals != nil, @"windowForModals must no be nil, modal sheet can't be attached.");

    PackageController *packageController = [[PackageController alloc] init];
    packageController.projectSettings = _projectSettings;
    [packageController showCreateNewPackageDialogForWindow:_windowForModals];
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