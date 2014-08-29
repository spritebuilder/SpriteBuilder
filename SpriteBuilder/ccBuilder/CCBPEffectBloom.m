//
//  CCBPEffectBloom.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/3/14.
//
//

#import "CCBPEffectBloom.h"
#import "EffectsManager.h"



@implementation CCBPEffectBloom
@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithBlurRadius:4 intensity:0.0f luminanceThreshold:0.0f];
}

-(id)serialize
{
	return @[SERIALIZE_PROPERTY(blurRadius,Float), SERIALIZE_PROPERTY(intensity,Float),SERIALIZE_PROPERTY(luminanceThreshold,Float)];
}

-(void)deserialize:(NSArray*)properties
{
	DESERIALIZE_PROPERTY(blurRadius, floatValue);
	DESERIALIZE_PROPERTY(intensity, floatValue);
	DESERIALIZE_PROPERTY(luminanceThreshold, floatValue);
	
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

@end
