#import "RMPackage.h"


@implementation RMPackage

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> Path: %@ ", [self class], self, self.dirPath];
}

@end