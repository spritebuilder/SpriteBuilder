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
        self.renamedFilesLookup = [[PublishRenamedFilesLookup alloc] initWithFlattenPaths:NO];
        self.audioQuality = DEFAULT_AUDIO_QUALITY;
    }

    return self;
}

@end