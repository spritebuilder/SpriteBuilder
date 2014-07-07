//
//  EffectContrastControl.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import "EffectViewController.h"
#import "CCBPEffectContrast.h"

@class CCBPEffectContrast;
@interface EffectContrastControl : EffectViewController
@property (nonatomic) CCBPEffectContrast<EffectProtocol> * effect;
@end
