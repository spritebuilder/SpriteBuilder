#import <Foundation/Foundation.h>
#import "PublishResolutions.h"

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
        self.resolution_4x = NO;
    }

    return self;
}

- (instancetype)initWithData:(id)data
{
    self = [self init];

    if (self)
    {
        for (NSNumber *resolution in data)
        {
            if ([resolution isEqualToNumber:@1])
            {
                self.resolution_1x = YES;
            }

            if ([resolution isEqualToNumber:@2])
            {
                self.resolution_2x = YES;
            }

            if ([resolution isEqualToNumber:@4])
            {
                self.resolution_4x = YES;
            }
        }
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

- (id)serialize
{
    return _internalList;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"1x: %@, 2x: %@, 4x: %@", @(_resolution_1x), @(_resolution_2x), @(_resolution_4x)];
}

@end
