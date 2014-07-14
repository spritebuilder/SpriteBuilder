//
//  CCBPEffectContrast.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "CCEffectContrast.h"
#import "EffectsManager.h"


@interface CCBPEffectContrast : CCEffectContrast <EffectProtocol>
@property (nonatomic,readonly) EffectDescription * effectDescription;
@end
