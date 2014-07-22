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
	return [self effectWithPixelBlurRadius:4 intensity:0.0f luminanceThreshold:0.0f];
}

-(id)serialize
{
	return @{@"blurRadius" : @(self.blurRadius),
			 @"intensity" : @(self.intensity),
			 @"luminanceThreshold" : @(self.luminanceThreshold) };
}

-(void)deserialize:(NSDictionary*)dict
{
	self.blurRadius = [dict[@"blurRadius"] floatValue];
	self.intensity = [dict[@"intensity"] floatValue];
	self.luminanceThreshold = [dict[@"luminanceThreshold"] floatValue];
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

@end
