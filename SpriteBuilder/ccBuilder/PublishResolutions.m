#import <Foundation/Foundation.h>
#import "PublishResolutions.h"

static NSString *const RESOLUTIONS_KEY_1X = @"RESOLUTIONS_KEY_1X";
static NSString *const RESOLUTIONS_KEY_2X = @"RESOLUTIONS_KEY_2X";
static NSString *const RESOLUTIONS_KEY_4X = @"RESOLUTIONS_KEY_4X";


@interface PublishResolutions()

@property (nonatomic, strong) NSMutableArray *internalList;

@end

@implementation PublishResolutions

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.internalList = [NSMutableArray arrayWithCapacity:3];

        self.resolution_1x = NO;
        self.resolution_2x = NO;
        self.resolution_4x = YES;
    }

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self init];

    if (self)
    {
        self.resolution_1x = [dictionary[RESOLUTIONS_KEY_1X] boolValue];
        self.resolution_2x = [dictionary[RESOLUTIONS_KEY_2X] boolValue];
        self.resolution_4x = [dictionary[RESOLUTIONS_KEY_4X] boolValue];
    }

    return self;
}

- (void)setResolution_1x:(BOOL)resolution_1x
{
    _resolution_1x = resolution_1x;

    [self updateInternalListForProperty:@"resolution_1x" withNumber:@1];
}

- (void)setResolution_2x:(BOOL)resolution_2x
{
    _resolution_2x = resolution_2x;

    [self updateInternalListForProperty:@"resolution_2x" withNumber:@2];
}

- (void)setResolution_4x:(BOOL)resolution_4x
{
    _resolution_4x = resolution_4x;

    [self updateInternalListForProperty:@"resolution_4x" withNumber:@4];
}

- (void)updateInternalListForProperty:(NSString *)propertyName withNumber:(NSNumber *)number
{
    NSNumber *res = [self valueForKey:propertyName];

    if ([res boolValue])
    {
        [_internalList addObject:number];
    }
    else
    {
        [_internalList removeObject:number];
    }
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained[])stackbuf count:(NSUInteger)len
{
    return [_internalList countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    result[RESOLUTIONS_KEY_1X] = @(_resolution_1x);
    result[RESOLUTIONS_KEY_2X] = @(_resolution_2x);
    result[RESOLUTIONS_KEY_4X] = @(_resolution_4x);

    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"1x: %@, 2x: %@, 4x: %@", @(_resolution_1x), @(_resolution_2x), @(_resolution_4x)];
}



@end
