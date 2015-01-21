    //
//  CCBPEffectColorChannelOffset.m
//  SpriteBuilder
//
//  Created by Thayer on 12/10/14.
//
//

#import "CCBPEffectColorChannelOffset.h"
#import "CCBDictionaryReader.h"
#import "CCBDictionaryWriter.h"
#import "EffectsUndoHelper.h"

@implementation CCBPEffectColorChannelOffset

@synthesize UUID;

+ (CCEffect<CCEffectProtocol>*)defaultConstruct
{
    return [self effectWithRedOffset:GLKVector2Make(0.0, 0.0) greenOffset:GLKVector2Make(0.0, 0.0) blueOffset:GLKVector2Make(0.0, 0.0)];
}

- (CGPoint)vectorToPoint:(GLKVector2)vector
{
    return CGPointMake(vector.x, vector.y);
}

- (GLKVector2)pointToVector:(CGPoint)point
{
    return GLKVector2Make(point.x, point.y);
}

- (id)serialize
{
    return @[@{@"name" : @"redOffsetWithPoint",   @"type" : @"Point", @"value": [CCBDictionaryWriter serializePoint:[self vectorToPoint:self
            .redOffset]] },
             @{@"name" : @"greenOffsetWithPoint", @"type" : @"Point", @"value": [CCBDictionaryWriter serializePoint:[self vectorToPoint:self
                     .greenOffset]] },
             @{@"name" : @"blueOffsetWithPoint",  @"type" : @"Point", @"value": [CCBDictionaryWriter serializePoint:[self vectorToPoint:self
                     .blueOffset]] },
             ];
}

- (void)deserialize:(NSArray*)properties
{
    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"redOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.redOffset = [self pointToVector:[CCBDictionaryReader deserializePoint:dict[@"value"]]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"greenOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.greenOffset = [self pointToVector:[CCBDictionaryReader deserializePoint:dict[@"value"]]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"blueOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.blueOffset = [self pointToVector:[CCBDictionaryReader deserializePoint:dict[@"value"]]];
    }];
}

- (EffectDescription*)effectDescription
{
    return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

- (void)willChangeValueForKey:(NSString *)key
{
    [EffectsUndoHelper handleUndoForKey:key effect:self];
    [super willChangeValueForKey:key];
}

@end
