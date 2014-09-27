	//
//  CCBPEffectBrightness.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "CCBPEffectBrightness.h"
#import "EffectsUndoHelper.h"


@implementation CCBPEffectBrightness 
@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithBrightness:0.4f];
}

-(id)serialize
{
	return @[SERIALIZE_PROPERTY(brightness,Float)];
}

-(void)deserialize:(NSArray*)properties
{
	DESERIALIZE_PROPERTY(brightness, floatValue);
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
