#import "ResourceShowInFinderCommand.h"

#import "RMResource.h"

@implementation ResourceShowInFinderCommand

- (void)execute
{
    RMResourceBase *resource = _resources.firstObject;

    NSString *path = [resource fullPath];
    if (path)
    {
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
    }
}


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"Show in Finder";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return (resources.count > 0);
}


@end