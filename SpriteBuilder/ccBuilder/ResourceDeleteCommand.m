#import "ResourceDeleteCommand.h"

#import "SCEventListenerProtocol.h"
#import "ResourceManager.h"
#import "RMPackage.h"
#import "RMResource.h"
#import "ResourceTypes.h"
#import "ProjectSettings.h"
#import "FeatureToggle.h"
#import "PackageRemover.h"

@implementation ResourceDeleteCommand

- (void)execute
{
    NSAssert(_projectSettings != nil ,@"Project settings must not be nil");
    NSAssert(_outlineView != nil ,@"OutlineView should be set");

    if (!_resources || _resources.count == 0)
    {
        return;
    }

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

    for (id resource in _resources)
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

    PackageRemover *packageRemover = [[PackageRemover alloc] init];
    packageRemover.projectSettings = _projectSettings;
    [packageRemover removePackagesFromProject:packagesPathsToDelete error:NULL];

    [_outlineView deselectAll:nil];

    [[ResourceManager sharedManager] reloadAllResources];
}


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"Delete";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return ([resources.firstObject isKindOfClass:[RMResource class]]
            || (resources.count > 0)
            || [resources.firstObject isKindOfClass:[RMPackage class]]);
}


@end