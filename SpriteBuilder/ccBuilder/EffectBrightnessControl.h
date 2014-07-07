//
//  EffectBrightnessControl.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import <Cocoa/Cocoa.h>
#import "CCBPEffectBrightness.h"
#import "EffectViewController.h"

@class CCBPEffectBrightness;
@interface EffectBrightnessControl : EffectViewController
@property (nonatomic) CCBPEffectBrightness<EffectProtocol> * effect;
@end
