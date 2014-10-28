#import "CCBPEffectInvert.h"

@implementation CCBPEffectInvert

@synthesize UUID;

+ (CCEffect <EffectProtocol> *)defaultConstruct
{
    return [[CCBPEffectInvert alloc] init];
}

- (id)serialize
{
    return [NSDictionary dictionary];
}

- (void)deserialize:(NSArray *)properties
{
    // Nothing to do;
}

- (EffectDescription *)effectDescription
{
    return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}



@end