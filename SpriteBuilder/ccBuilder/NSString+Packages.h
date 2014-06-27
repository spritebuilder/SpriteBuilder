#import <Foundation/Foundation.h>

@interface NSString (Packages)

- (BOOL)hasPackageSuffix;

- (NSString *)stringByAppendingPackageSuffix;
@end