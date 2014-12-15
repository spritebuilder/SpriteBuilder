//
//  CCBPEffectLighting.h
//  SpriteBuilder
//
//  Created by Thayer J Andrews on 11/18/14.
//
//

#import "EffectsManager.h"
#import "CCEffectLighting.h"


@interface CCBPEffectLighting : CCEffectLighting <EffectProtocol>

@property (nonatomic,readonly) EffectDescription * effectDescription;

@end
