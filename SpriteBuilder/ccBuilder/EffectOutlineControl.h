//
//  EffectOutlineControl.h
//  SpriteBuilder
//
//  Created by Oleg Osin on 12/13/14.
//
//

#import "EffectViewController.h"

#if CC_EFFECTS_EXPERIMENTAL

#import "CCBPEffectOutline.h"

@interface EffectOutlineControl : EffectViewController

@property (nonatomic,strong) NSColor* color;
@property (nonatomic) CCBPEffectOutline * effect;

@end

#endif
