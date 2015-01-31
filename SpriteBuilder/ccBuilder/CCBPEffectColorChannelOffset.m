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
    return [self effectWithRedOffset:CGPointMake(0.0, 0.0) greenOffset:CGPointMake(0.0, 0.0) blueOffset:CGPointMake(0.0, 0.0)];
}

- (id)serialize
{
    return @[@{@"name" : @"redOffsetWithPoint",   @"type" : @"Point", @"value": [CCBDictionaryWriter serializePoint:self.redOffset] },
             @{@"name" : @"greenOffsetWithPoint", @"type" : @"Point", @"value": [CCBDictionaryWriter serializePoint:self.greenOffset] },
             @{@"name" : @"blueOffsetWithPoint",  @"type" : @"Point", @"value": [CCBDictionaryWriter serializePoint:self.blueOffset] },
             ];
}

- (void)deserialize:(NSArray*)properties
{
    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"redOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.redOffset = [CCBDictionaryReader deserializePoint:dict[@"value"]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"greenOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.greenOffset = [CCBDictionaryReader deserializePoint:dict[@"value"]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"blueOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.blueOffset = [CCBDictionaryReader deserializePoint:dict[@"value"]];
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
