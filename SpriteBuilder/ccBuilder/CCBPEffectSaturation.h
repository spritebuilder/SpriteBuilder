//
//  CCBPEffectSaturation.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "EffectsManager.h"
#import "CCEffectSaturation.h"


@interface CCBPEffectSaturation : CCEffectSaturation <EffectProtocol>
@property (nonatomic,readonly) EffectDescription * effectDescription;

@end
