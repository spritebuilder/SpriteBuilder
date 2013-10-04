//
//  CCBPPhysicsNode.m
//  SpriteBuilder
//
//  Created by Viktor on 10/4/13.
//
//

#import "CCBPPhysicsNode.h"

@implementation CCBPPhysicsNode

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    _sleepTimeThreshold = 0.5f;
    
    return self;
}

@end
