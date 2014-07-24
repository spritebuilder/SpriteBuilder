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
        self.resolutions = @[@"tablet", @"tablethd", @"phone", @"phonehd"];
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
        [result addObject:@"phone"];
    }

    if (_resolution_phonehd)
    {
        [result addObject:@"phonehd"];
    }

    if (_resolution_tablet)
    {
        [result addObject:@"tablet"];
    }

    if (_resolution_tablethd)
    {
        [result addObject:@"tablethd"];
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
        if ([resolution isEqualToString:@"phone"])
        {
            self.resolution_phone = YES;
        }

        if ([resolution isEqualToString:@"phonehd"])
        {
            self.resolution_phonehd = YES;
        }

        if ([resolution isEqualToString:@"tablet"])
        {
            self.resolution_tablet = YES;
        }

        if ([resolution isEqualToString:@"tablethd"])
        {
            self.resolution_tablethd = YES;
        }
    }
}

@end