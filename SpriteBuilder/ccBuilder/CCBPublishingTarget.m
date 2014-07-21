#import "CCBPublishingTarget.h"
#import "ProjectSettings.h"
#import "PublishRenamedFilesLookup.h"


@implementation CCBPublishingTarget

- (id)init
{
    self = [super init];
    if (self)
    {
        self.publishEnvironment = kCCBPublishEnvironmentDevelop;
        self.publishedPNGFiles = [NSMutableSet set];
        self.publishedSpriteSheetFiles = [[NSMutableSet alloc] init];
        self.renamedFilesLookup = [[PublishRenamedFilesLookup alloc] initWithFlattenPaths:NO];
    }

    return self;
}

@end