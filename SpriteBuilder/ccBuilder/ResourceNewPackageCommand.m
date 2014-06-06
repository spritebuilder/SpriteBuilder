#import "ResourceCommandProtocol.h"

#import "ResourceNewPackageCommand.h"
#import "ProjectSettings.h"
#import "PackageController.h"
#import "AppDelegate.h"


@implementation ResourceNewPackageCommand

- (void)execute
{
    PackageController *packageController = [[PackageController alloc] init];
    packageController.projectSettings = _projectSettings;
    [packageController showCreateNewPackageDialogForWindow:[AppDelegate appDelegate].window];
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