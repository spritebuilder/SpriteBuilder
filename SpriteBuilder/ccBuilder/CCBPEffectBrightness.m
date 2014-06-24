//
//  CCBPEffectBrightness.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "CCBPEffectBrightness.h"

@implementation CCBPEffectBrightness 

+(CCEffect*)defaultConstruct
{
	return [self effectWithBrightness:3.0f];
}

-(id)serialize
{
	return @{@"brightness" : @(self.brightness)};
}
-(void)deserialize:(NSDictionary*)dict
{
	self.brightness = [dict[@"brightness"] floatValue];
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

@end
