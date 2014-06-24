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
@property (nonatomic,readonly) NSArray * effects;

-(void)addEffect:(EffectDescription*)effectDescription;
-(void)removeEffect:(EffectDescription*)effectDescription;


@end



@interface CCBPEffectNode : CCEffectNode <CCEffectNodeProtocol>
{
	
}

@property (nonatomic) NSArray * effects;
@end
