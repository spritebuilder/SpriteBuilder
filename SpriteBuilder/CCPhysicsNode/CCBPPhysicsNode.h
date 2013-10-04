//
//  CCBPPhysicsNode.h
//  SpriteBuilder
//
//  Created by Viktor on 10/4/13.
//
//

#import "CCNode.h"

@interface CCBPPhysicsNode : CCNode

@property (nonatomic,assign) CGPoint gravity;
@property (nonatomic,assign) float sleepTimeThreshold;

@end
