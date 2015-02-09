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
        self.resolutions = @[@(RESOLUTION_1X), @(RESOLUTION_2X), @(RESOLUTION_4X)];
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

    if (_resolution_1x)
    {
        [result addObject:@(RESOLUTION_1X)];
    }

    if (_resolution_2x)
    {
        [result addObject:@(RESOLUTION_2X)];
    }

    if (_resolution_4x)
    {
        [result addObject:@(RESOLUTION_4X)];
    }

    return result;
}

- (void)setResolutions:(NSArray *)resolutions
{
    self.resolution_1x = NO;
    self.resolution_2x = NO;
    self.resolution_4x = NO;

    for (NSNumber *contentScale in resolutions)
    {
        if ([contentScale isEqualTo:@(RESOLUTION_1X)])
        {
            self.resolution_1x = YES;
        }

        if ([contentScale isEqualTo:@(RESOLUTION_2X)])
        {
            self.resolution_2x = YES;
        }

        if ([contentScale isEqualTo:@(RESOLUTION_4X)])
        {
            self.resolution_4x = YES;
        }
    }
}

@end