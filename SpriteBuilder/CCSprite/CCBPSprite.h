//
//  CCBPSprite.h
//  SpriteBuilder
//
//  Created by Viktor on 12/17/13.
//
//

#import "CCSprite.h"
#import "EffectsManager.h"

@interface CCBPSprite : CCSprite <CCEffectNodeProtocol>
@property (nonatomic) NSArray * effects;

@end
