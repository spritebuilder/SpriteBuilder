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

@end
