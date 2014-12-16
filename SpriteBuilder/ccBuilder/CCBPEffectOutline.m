//
//  CCBPEffectOutline.m
//  SpriteBuilder
//
//  Created by Oleg Osin on 12/13/14.
//
//

#import "CCBPEffectOutline.h"
#import "EffectsUndoHelper.h"
#import "CCBReaderInternal.h"
#import "CCBWriterInternal.h"


@implementation CCBPEffectOutline
@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
    return [self effectWithOutlineColor:[CCColor redColor] outlineWidth:2];
}

-(id)serialize
{
    return @[SERIALIZE_PROPERTY(outlineWidth,Integer),
             @{@"name" : @"outlineColor", @"type" : @"Color4", @"value": [CCBWriterInternal serializeColor4:self.outlineColor] },
             ];
}

-(void)deserialize:(NSArray*)properties
{
    DESERIALIZE_PROPERTY(outlineWidth, intValue);
    
    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"outlineColor"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.outlineColor = [CCBReaderInternal deserializeColor4:dict[@"value"]];
    }];

}

-(EffectDescription*)effectDescription
{
    return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

- (void)willChangeValueForKey:(NSString *)key
{
    [EffectsUndoHelper handleUndoForKey:key effect:self];
    [super willChangeValueForKey:key];
}

@end
