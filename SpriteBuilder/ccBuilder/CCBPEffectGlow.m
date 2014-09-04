//
//  CCBPEffectGlow.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "CCBPEffectGlow.h"
#import "EffectsManager.h"

@implementation CCBPEffectGlow


+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithBlurStrength:0.007f];
}

-(id)serialize
{
	return @{@"blurStrength" : @(self.blurStrength)};
}
-(void)deserialize:(NSDictionary*)dict
{
	self.blurStrength = [dict[@"blurStrength"] floatValue];
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}



@end
