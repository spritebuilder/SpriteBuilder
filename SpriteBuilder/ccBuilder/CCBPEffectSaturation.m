//
//  CCBPEffectSaturation.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "CCBPEffectSaturation.h"
#import "EffectsManager.h"


@implementation CCBPEffectSaturation
@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithSaturation:0.5f];
}


-(id)serialize
{
	return @[SERIALIZE_PROPERTY(saturation,Float)];
}

-(void)deserialize:(NSArray*)properties
{
	DESERIALIZE_PROPERTY(saturation, floatValue);
	
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}



@end
