//
//  EffectsUndoHelper.h
//  SpriteBuilder
//
//  Created by Viktor on 9/26/14.
//
//

#import <Foundation/Foundation.h>
#import "EffectsManager.h"

@interface EffectsUndoHelper : NSObject

+ (void) handleUndoForKey:(NSString*)key effect:(id<EffectProtocol>) effect;

@end
