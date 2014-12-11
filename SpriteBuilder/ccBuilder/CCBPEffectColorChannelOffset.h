//
//  CCBPEffectColorChannelOffset.h
//  SpriteBuilder
//
//  Created by Thayer on 12/10/14.
//
//

#import "CCEffectColorChannelOffset.h"
#import "EffectsManager.h"

@interface CCBPEffectColorChannelOffset : CCEffectColorChannelOffset <EffectProtocol>

@property (nonatomic,readonly) EffectDescription *effectDescription;
@property (nonatomic,assign) float redOffsetX;
@property (nonatomic,assign) float redOffsetY;
@property (nonatomic,assign) float greenOffsetX;
@property (nonatomic,assign) float greenOffsetY;
@property (nonatomic,assign) float blueOffsetX;
@property (nonatomic,assign) float blueOffsetY;

@end
