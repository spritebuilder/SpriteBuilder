#import "RMPackage.h"
#import "MiscConstants.h"

@interface RMPackage()

@property (nonatomic, copy, readwrite) NSString *name;

@end


@implementation RMPackage

- (NSString *)name
{
    NSString *fullName = [self.dirPath lastPathComponent];
    NSRange suffixFromBack = [fullName rangeOfString:[NSString stringWithFormat:@".%@", PACKAGE_NAME_SUFFIX]
                                             options:NSBackwardsSearch | NSCaseInsensitiveSearch];

    return [fullName stringByReplacingCharactersInRange:suffixFromBack withString:@""];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> Path: %@ ", [self class], self, self.dirPath];
}

@end