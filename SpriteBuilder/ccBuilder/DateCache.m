#import "DateCache.h"


@implementation DateCache
{
    NSMutableDictionary *_modifiedDatesCache;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _modifiedDatesCache = [NSMutableDictionary dictionary];
    }

    return self;
}

- (NSDate *)cachedDateForKey:(NSString *)key
{
	return [_modifiedDatesCache objectForKey:key];
}

- (void)setCachedDate:(id)date forKey:(NSString *)key
{
	[_modifiedDatesCache setObject:date forKey:key];
}

@end