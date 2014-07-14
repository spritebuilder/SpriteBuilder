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

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithSaturation:0.5f];
}

-(id)serialize
{
	return @{@"saturation" : @(self.saturation)};
}
-(void)deserialize:(NSDictionary*)dict
{
	self.saturation = [dict[@"saturation"] floatValue];
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}



@end
