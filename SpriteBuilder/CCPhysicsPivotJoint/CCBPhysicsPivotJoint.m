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

-(int)hitTestOutlet:(CGPoint)point
{
    point = [self convertToNodeSpace:point];
    
    if(ccpDistanceSQ(point, bodyAOutlet.position) < 3.0f * 3.0f)
    {
        return 0;
    }
    
    if(ccpDistanceSQ(point, bodyBOutlet.position) < 3.0f * 3.0f)
    {
        return 1;
    }
    
    return -1;
}

-(void)setBodyA:(CCNode *)aBodyA
{
    bodyA = aBodyA;
    [self resetOutletStatus];
}

-(void)setBodyB:(CCNode *)aBodyB
{
    bodyB = aBodyB;
    [self resetOutletStatus];
}

-(CCNode*)bodyA
{
    return bodyA;
}

-(CCNode*)bodyB
{
    return bodyB;
}

-(void)resetOutletStatus
{
    bodyAOutlet.visible = self.bodyA ? NO : YES;
    bodyBOutlet.visible = self.bodyB ? NO : YES;
    
    bodyAOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];
    bodyBOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];

}

-(CGPoint)outletPos:(int)idx
{
    return idx ==0 ? bodyAOutlet.position : bodyBOutlet.position;    
}



-(void)setOutletStatus:(int)idx value:(BOOL)value
{
    CCSprite * bodyOutlet = idx == 0 ? bodyAOutlet : bodyBOutlet;
    if(value)
    {
        bodyOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-set.png"];
    }
    else
    {
        bodyOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];
    }
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

-(CGPoint)anchorA
{
    return anchorA;
}

-(void)setAnchorA:(CGPoint)aAnchorA
{
    anchorA = aAnchorA;
    
}


@end
