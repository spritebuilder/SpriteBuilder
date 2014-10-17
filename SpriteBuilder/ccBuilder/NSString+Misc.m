#import "NSString+Misc.h"


@implementation NSString (Misc)

- (BOOL)isEmpty
{
    return [self length] == 0
           || ![[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];

}

@end