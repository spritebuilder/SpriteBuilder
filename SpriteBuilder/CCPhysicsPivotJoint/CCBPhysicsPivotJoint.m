//
//  CCBPPhysicsPivotJoint.m
//  SpriteBuilder
//
//  Created by John Twigg
//
//

#import "CCBPhysicsPivotJoint.h"

@interface  ScaleFreeNode : CCNode
@end

@implementation ScaleFreeNode

-(void)visit
{
    CCNode * parent = self.parent;
    float scale = 1.0f;
    while (parent) {
        scale *= parent.scale;
        parent = parent.parent;
    }
    
    
    self.scale = 1.0f/scale;
    
    [super visit];
    
    
    
}

@end

@implementation CCBPhysicsJoint

- (id) init
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    scaleFreeNode = [ScaleFreeNode node];
    [self addChild:scaleFreeNode];
    


    bodyAOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyAOutlet.position = ccp(-10.0f,-10.0f);
    [scaleFreeNode addChild:bodyAOutlet];
    
    bodyBOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyBOutlet.position = ccp(10.0f,-10.0f);
    [scaleFreeNode addChild:bodyBOutlet];
    
    return self;
}


@end

@implementation CCBPhysicsPivotJoint

- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }
    
    CCSprite* joint = [CCSprite spriteWithImageNamed:@"joint-pivot.png"];
    CCSprite* jointAnchor = [CCSprite spriteWithImageNamed:@"joint-anchor.png"];
    
    [scaleFreeNode addChild:joint];
    [scaleFreeNode addChild:jointAnchor];
    
    
    return self;
}


-(void)visit
{
    [super visit];
}

@end
