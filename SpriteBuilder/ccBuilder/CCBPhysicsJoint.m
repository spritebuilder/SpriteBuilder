//
//  CCBPhysicsJoint.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCBPhysicsJoint.h"
#import "CCScaleFreeNode.h"

static const float kOutletOffset = 20.0f;

@implementation CCBPhysicsJoint

- (id) init
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    
    scaleFreeNode = [CCScaleFreeNode node];
    [self addChild:scaleFreeNode];
    
    bodyAOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyAOutlet.position = ccp(-kOutletOffset,-kOutletOffset);
    [scaleFreeNode addChild:bodyAOutlet];
    
    bodyBOutlet = [CCSprite spriteWithImageNamed:@"joint-outlet-unset.png"];
    bodyBOutlet.position = ccp(kOutletOffset,-kOutletOffset);
    [scaleFreeNode addChild:bodyBOutlet];
    
    return self;
}

-(int)hitTestOutlet:(CGPoint)point
{
    point = [self convertToNodeSpace:point];
    
    if(ccpDistance(point, bodyAOutlet.position) < 3.0f * 3.0f)
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