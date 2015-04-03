#import "PublishOSSettings.h"
#import "MiscConstants.h"
#import "PublishResolutions.h"

NSString *const KEY_RESOLUTIONS = @"resolutions";
NSString *const KEY_AUDIO_QUALITY = @"audio_quality";

@implementation PublishOSSettings

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.audio_quality = DEFAULT_AUDIO_QUALITY;
        self.resolutions = [[PublishResolutions alloc] init];
    }

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self init];

    if (self && dictionary)
    {
        self.audio_quality = [dictionary[KEY_AUDIO_QUALITY] integerValue];
        self.resolutions = [[PublishResolutions alloc] initWithData:dictionary[KEY_RESOLUTIONS]];
    }

    return self;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

    result[KEY_AUDIO_QUALITY] = @(_audio_quality);
    result[KEY_RESOLUTIONS] = [self.resolutions serialize];

    return result;
}

@end
