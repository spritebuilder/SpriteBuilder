    //
//  CCBPEffectColorChannelOffset.m
//  SpriteBuilder
//
//  Created by Thayer on 12/10/14.
//
//

#import "CCBPEffectColorChannelOffset.h"
#import "CCBReaderInternal.h"
#import "CCBWriterInternal.h"
#import "EffectsUndoHelper.h"

@implementation CCBPEffectColorChannelOffset

@synthesize UUID;

+ (CCEffect<CCEffectProtocol>*)defaultConstruct
{
    return [self effectWithRedOffset:CGPointMake(0.0, 0.0) greenOffset:CGPointMake(0.0, 0.0) blueOffset:CGPointMake(0.0, 0.0)];
}

//- (CGPoint)vectorToPoint:(GLKVector2)vector
//{
//    return CGPointMake(vector.x, vector.y);
//}
//
//- (GLKVector2)pointToVector:(CGPoint)point
//{
//    return GLKVector2Make(point.x, point.y);
//}

- (id)serialize
{
    return @[@{@"name" : @"redOffsetWithPoint",   @"type" : @"Point", @"value": [CCBWriterInternal serializePoint:self.redOffset] },
             @{@"name" : @"greenOffsetWithPoint", @"type" : @"Point", @"value": [CCBWriterInternal serializePoint:self.greenOffset] },
             @{@"name" : @"blueOffsetWithPoint",  @"type" : @"Point", @"value": [CCBWriterInternal serializePoint:self.blueOffset] },
             ];
}

- (void)deserialize:(NSArray*)properties
{
    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"redOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.redOffset = [CCBReaderInternal deserializePoint:dict[@"value"]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"greenOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.greenOffset = [CCBReaderInternal deserializePoint:dict[@"value"]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"blueOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.blueOffset = [CCBReaderInternal deserializePoint:dict[@"value"]];
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
