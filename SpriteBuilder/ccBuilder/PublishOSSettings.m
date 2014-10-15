#import "PublishOSSettings.h"
#import "MiscConstants.h"

NSString *const KEY_RESOLUTIONS = @"resolutions";
NSString *const KEY_AUDIO_QUALITY = @"audio_quality";

@implementation PublishOSSettings

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.audio_quality = DEFAULT_AUDIO_QUALITY;
        self.resolutions = @[RESOLUTION_TABLET, RESOLUTION_TABLET_HD, RESOLUTION_PHONE, RESOLUTION_PHONE_HD];
    }

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self init];

    if (self && dictionary)
    {
        self.audio_quality = [dictionary[KEY_AUDIO_QUALITY] integerValue];
        self.resolutions = dictionary[KEY_RESOLUTIONS];
    }

    return self;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

    result[KEY_AUDIO_QUALITY] = @(_audio_quality);
    result[KEY_RESOLUTIONS] = self.resolutions;

    return result;
}

- (NSArray *)resolutions
{
    NSMutableArray *result = [NSMutableArray array];

    if (_resolution_phone)
    {
        [result addObject:RESOLUTION_PHONE];
    }

    if (_resolution_phonehd)
    {
        [result addObject:RESOLUTION_PHONE_HD];
    }

    if (_resolution_tablet)
    {
        [result addObject:RESOLUTION_TABLET];
    }

    if (_resolution_tablethd)
    {
        [result addObject:RESOLUTION_TABLET_HD];
    }

    return result;
}

- (void)setResolutions:(NSArray *)resolutions
{
    self.resolution_phone = NO;
    self.resolution_phonehd = NO;
    self.resolution_tablet = NO;
    self.resolution_tablethd = NO;

    for (NSString *resolution in resolutions)
    {
        if ([resolution isEqualToString:RESOLUTION_PHONE])
        {
            self.resolution_phone = YES;
        }

        if ([resolution isEqualToString:RESOLUTION_PHONE_HD])
        {
            self.resolution_phonehd = YES;
        }

        if ([resolution isEqualToString:RESOLUTION_TABLET])
        {
            self.resolution_tablet = YES;
        }

        if ([resolution isEqualToString:RESOLUTION_TABLET_HD])
        {
            self.resolution_tablethd = YES;
        }
    }
}

@end