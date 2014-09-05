//
//  CCBPEffectBlur
//  SpriteBuilder
//
//  Created by John Twigg on 7/3/14.
//
//

#import "CCBPEffectBlur.h"
#import "EffectsManager.h"


@implementation CCBPEffectBlur
@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
	return [[self alloc] init];
}

-(id)serialize
{
	return @[SERIALIZE_PROPERTY(blurRadius,Int)];
}

-(void)deserialize:(NSArray*)properties
{
	DESERIALIZE_PROPERTY(blurRadius, intValue);
}


-(EffectDescription*)effectDescription
{
	return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

@end
