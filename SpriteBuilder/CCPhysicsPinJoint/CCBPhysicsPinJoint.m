//
//  CCBPhysicsPinJoint.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCBPhysicsPinJoint.h"

@interface CCBPhysicsPinJoint()
{
    CCSprite9Slice * jointBody;
}


@end

@implementation CCBPhysicsPinJoint


- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }
    
    return self;
}

-(void)setupBody
{
    jointBody = [CCSprite9Slice spriteWithImageNamed:@"joint-distance.png"];
    jointBody.marginLeft = 0.25;
    jointBody.marginRight = 0.25;
    
    [scaleFreeNode addChild:jointBody];
}

-(void)setBodyA:(CCNode *)aBodyA
{
    [super setBodyA:aBodyA];
    
    
}


@end
