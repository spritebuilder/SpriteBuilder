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
    
    //self.contentSizeType = CCSizeTypeMake(CCSizeUnitNormalized, CCSizeUnitNormalized);
    //self.contentSize     = CGSizeMake(1,1);
    
    return self;
}

@end
