//
//  CCBPEffectLighting.m
//  SpriteBuilder
//
//  Created by Thayer J Andrews on 11/18/14.
//
//

#import "CCBPEffectLighting.h"
#import "EffectsManager.h"
#import "EffectsUndoHelper.h"

@implementation CCBPEffectLighting
@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
    return [self effectWithGroups:nil specularColor:[CCColor whiteColor] shininess:1.0f];
}


-(id)serialize
{
    return @[SERIALIZE_PROPERTY(shininess,Float)];
}

-(void)deserialize:(NSArray*)properties
{
    DESERIALIZE_PROPERTY(shininess, floatValue);
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
