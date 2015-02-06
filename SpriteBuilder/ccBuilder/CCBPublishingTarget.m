#import "CCBPublishingTarget.h"
#import "ProjectSettings.h"
#import "PublishRenamedFilesLookup.h"
#import "MiscConstants.h"


@implementation CCBPublishingTarget

- (id)init
{
    self = [super init];
    if (self)
    {
        self.publishEnvironment = kCCBPublishEnvironmentDevelop;
        self.publishedPNGFiles = [NSMutableSet set];
        self.publishedSpriteSheetFiles = [[NSMutableSet alloc] init];
        self.renamedFilesLookup = [[PublishRenamedFilesLookup alloc] init];
    }

    return self;
}

@end