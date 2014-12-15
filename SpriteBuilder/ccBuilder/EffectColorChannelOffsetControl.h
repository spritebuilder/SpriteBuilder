//
//  EffectColorChannelOffsetControl.h
//  SpriteBuilder
//
//  Created by Thayer on 12/10/14.
//
//

#import "EffectViewController.h"
#import "CCBPEffectColorChannelOffset.h"

@class CCBPEffectColorChannelOffset;

@interface EffectColorChannelOffsetControl : EffectViewController
@property (nonatomic) CCBPEffectColorChannelOffset *effect;
@property (nonatomic,assign) float redOffsetX;
@property (nonatomic,assign) float redOffsetY;
@property (nonatomic,assign) float greenOffsetX;
@property (nonatomic,assign) float greenOffsetY;
@property (nonatomic,assign) float blueOffsetX;
@property (nonatomic,assign) float blueOffsetY;
@end
