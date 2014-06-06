#import "ResourceCommandContextMenuProtocol.h"

#import "ResourceCreateKeyframesCommand.h"
#import "SequencerUtil.h"


@implementation ResourceCreateKeyframesCommand

- (void)execute
{
    [SequencerUtil createFramesFromSelectedResources];
}


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"Create Keyframes from Selection";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return (resources.count > 0);
}

@end