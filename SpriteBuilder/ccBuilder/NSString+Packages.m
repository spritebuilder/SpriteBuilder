#import "NSString+Packages.h"
#import "MiscConstants.h"


@implementation NSString (Packages)

- (BOOL)hasPackageSuffix
{
    return [[self lastPathComponent] hasSuffix:PACKAGE_NAME_SUFFIX];
}

- (NSString *)pathByAppendingPackageSuffix
{
    return [NSString stringWithFormat:@"%@.%@", self, PACKAGE_NAME_SUFFIX];
}

@end