//
//  CCBPLayerColor.h
//  SpriteBuilder
//
//  Created by Viktor on 9/12/13.
//
//

#import "EffectsManager.h"
#import "CCEffectNode.h"
#import "CCEffect.h"



@protocol CCEffectNodeProtocol <NSObject>
@required
@property (nonatomic,readonly) NSArray * effectDescriptors;
@property (nonatomic) NSArray * effects;

-(void)addEffect:(CCEffect<EffectProtocol>*)effect;
-(void)removeEffect:(CCEffect<EffectProtocol>*)effect;

@end

#ifdef SB_EFFECTS_ENABLED

@interface CCBPEffectNode : CCEffectNode <CCEffectNodeProtocol>
{
	
}

@property (nonatomic) NSArray * effects;



@end

#endif
