//
//  CCBPEffectContrast.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "CCBPEffectContrast.h"
#import "EffectsManager.h"



@implementation CCBPEffectContrast
@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithContrast:0.6f];
}


-(id)serialize
{
	return @[SERIALIZE_PROPERTY(contrast,Float)];
}


-(void)deserialize:(NSArray*)properties
{
	DESERIALIZE_PROPERTY(contrast, floatValue);
}




-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

@end

