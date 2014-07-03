//
//  CCBPEffectPixelate.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "CCBPEffectPixelate.h"

@implementation CCBPEffectPixelate



+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithBlockSize:4.0f];
}

-(id)serialize
{
	return @{@"blockSize" : @(self.blockSize)};
}
-(void)deserialize:(NSDictionary*)dict
{
	self.blockSize = [dict[@"blockSize"] floatValue];
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}




@end
