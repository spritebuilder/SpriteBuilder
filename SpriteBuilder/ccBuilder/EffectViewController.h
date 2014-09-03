//
//  EffectViewController.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/24/14.
//
//

#import <Cocoa/Cocoa.h>
#import "EffectsManager.h"


@interface EffectViewController : NSViewController

@property (nonatomic) id<EffectProtocol> effect;
@property (nonatomic) BOOL highlight;
@end
