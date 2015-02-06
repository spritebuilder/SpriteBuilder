#import "NSNumber+ImageResolutions.h"


@implementation NSNumber (ImageResolutions)

- (NSString *)resolutionTag
{
    if ([self isLessThanOrEqualTo:@0])
    {
        return nil;
    }

    return [NSString stringWithFormat:@"-%@x", self];
}

@end
