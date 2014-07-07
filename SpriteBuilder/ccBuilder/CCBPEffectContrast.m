//
//  CCBPEffectContrast.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "CCBPEffectContrast.h"
#import "EffectsManager.h"

#ifdef SB_EFFECTS_ENABLED
@implementation CCBPEffectContrast


+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithContrast:0.6f];
}

-(id)serialize
{
	return @{@"contrast" : @(self.contrast)};
}
-(void)deserialize:(NSDictionary*)dict
{
	self.contrast = [dict[@"contrast"] floatValue];
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

@end

#endif