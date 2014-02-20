//
//  CCBPhysicsPinJoint.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCBPhysicsPinJoint.h"

@implementation CCBPhysicsPinJoint


- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }
    
    scaleFreeNode.scale = 1.0f;
    
    CCSprite* joint = [CCSprite spriteWithImageNamed:@"joint-distance.png"];
    
    [scaleFreeNode addChild:joint];
    
    
    return self;
}


@end
