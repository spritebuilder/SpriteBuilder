//
//  CCBPEffectPixelate.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "CCBPEffectPixelate.h"
#import "NSArray+Query.h"


@implementation CCBPEffectPixelate
@synthesize UUID;


+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [self effectWithBlockSize:4.0f];
}

-(id)serialize
{
	return @[SERIALIZE_PROPERTY(blockSize,Float)];
}
-(void)deserialize:(NSArray *)properties
{

	DESERIALIZE_PROPERTY(blockSize, floatValue);


}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}




@end
