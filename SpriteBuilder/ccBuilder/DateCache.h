#import <Foundation/Foundation.h>


@interface DateCache : NSObject

- (NSDate *)cachedDateForKey:(NSString *)key;

- (void)setCachedDate:(id)date forKey:(NSString *)key;

@end