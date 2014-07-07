	//
//  CCBPEffectBrightness.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "CCBPEffectBrightness.h"

#ifdef SB_EFFECTS_ENABLED
@implementation CCBPEffectBrightness 

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithBrightness:0.4f];
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
#endif