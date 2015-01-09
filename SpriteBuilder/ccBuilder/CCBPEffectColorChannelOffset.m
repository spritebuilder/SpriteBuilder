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
    return [self effectWithRedOffsetWithPoint:CGPointMake(0.0f, 0.0f) greenOffsetWithPoint:CGPointMake(0.0f, 0.0f) blueOffsetWithPoint:CGPointMake(0.0f, 0.0f)];
}


- (id)serialize
{
    return @[@{@"name" : @"redOffsetWithPoint",   @"type" : @"Point", @"value": [CCBWriterInternal serializePoint:self.redOffsetWithPoint] },
             @{@"name" : @"greenOffsetWithPoint", @"type" : @"Point", @"value": [CCBWriterInternal serializePoint:self.greenOffsetWithPoint] },
             @{@"name" : @"blueOffsetWithPoint",  @"type" : @"Point", @"value": [CCBWriterInternal serializePoint:self.blueOffsetWithPoint] },
             ];
}

- (void)deserialize:(NSArray*)properties
{
    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"redOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.redOffsetWithPoint = [CCBReaderInternal deserializePoint:dict[@"value"]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"greenOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.greenOffsetWithPoint = [CCBReaderInternal deserializePoint:dict[@"value"]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"blueOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.blueOffsetWithPoint = [CCBReaderInternal deserializePoint:dict[@"value"]];
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
