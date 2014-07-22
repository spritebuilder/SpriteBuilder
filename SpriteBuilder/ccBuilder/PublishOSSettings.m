#import "PublishOSSettings.h"
#import "MiscConstants.h"

@implementation PublishOSSettings

- (id)init
{
    self = [super init];

    if (self)
    {
        self.audio_quality = DEFAULT_AUDIO_QUALITY;
    }

    return self;
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