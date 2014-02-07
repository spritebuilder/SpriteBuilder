//
//  CCBPPhysicsPivotJoint.m
//  SpriteBuilder
//
//  Created by John Twigg
//
//

#import "CCBPPhysicsPivotJoint.h"

@implementation CCBPhysicsJoint


@end

@implementation CCBPPhysicsPivotJoint

- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }
    
    CCSprite* joint = [CCSprite spriteWithImageNamed:@"joint-pivot.png"];
    CCSprite* jointAnchor = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [self addChild:joint];
    [self addChild:jointAnchor];
    
    
    return self;
}

@end
