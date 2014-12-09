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
	return _modifiedDatesCache[key];
}

- (void)setCachedDate:(id)date forKey:(NSString *)key
{
	_modifiedDatesCache[key] = date;
}

@end