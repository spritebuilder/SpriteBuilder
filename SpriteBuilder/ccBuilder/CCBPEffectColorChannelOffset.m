//
//  CCBPEffectHue.m
//  SpriteBuilder
//
//  Created by Viktor on 9/18/14.
//
//

#import "CCBPEffectHue.h"
#import "EffectsUndoHelper.h"

@implementation CCBPEffectHue

@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
    return [self effectWithHue:0];
}


-(id)serialize
{
    return @[SERIALIZE_PROPERTY(hue,Float)];
}

-(void)deserialize:(NSArray*)properties
{
    DESERIALIZE_PROPERTY(hue, floatValue);
    
}

-(EffectDescription*)effectDescription
{
    return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

- (void) willChangeValueForKey:(NSString *)key
{
    [EffectsUndoHelper handleUndoForKey:key effect:self];
    [super willChangeValueForKey:key];
}

@end
