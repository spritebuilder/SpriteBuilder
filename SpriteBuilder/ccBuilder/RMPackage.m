#import "RMPackage.h"


@implementation RMPackage

- (NSString *)description
{
    return [NSString stringWithFormat:@"Path: %@ ", self.dirPath];
}

@end