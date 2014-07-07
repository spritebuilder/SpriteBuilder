//
//  CCBPEffectBloom.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/3/14.
//
//

#import "CCBPEffectBloom.h"
#import "EffectsManager.h"

#ifdef SB_EFFECTS_ENABLED

@implementation CCBPEffectBloom


+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithPixelBlurRadius:4 intensity:0.5f luminanceThreshold:0.5f];
}

-(id)serialize
{
	return @{@"blurRadius" : @(self.blurRadius),
			 @"intensity" : @(self.intensity),
			 @"luminanceThreshold" : @(self.luminanceThreshold) };
}

-(void)deserialize:(NSDictionary*)dict
{
	self.blurRadius = [dict[@"blurRadius"] integerValue];
	self.intensity = [dict[@"intensity"] integerValue];
	self.luminanceThreshold = [dict[@"luminanceThreshold"] integerValue];
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

@end
#endif