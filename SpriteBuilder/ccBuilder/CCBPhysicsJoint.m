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
{

}
@synthesize bodyA;
@synthesize bodyB;
@synthesize isSelected;
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

-(void)visit
{
    [self updateSelectionUI];
    [super visit];
}

-(void)updateSelectionUI
{
    
    if(self.isSelected)
    {
        bodyAOutlet.visible = self.bodyA ? NO : YES;
        bodyBOutlet.visible = self.bodyB ? NO : YES;

    }
    else
    {
        bodyAOutlet.visible = NO;
        bodyBOutlet.visible = NO;
    }
    
    isSelected = NO;
}

-(int)hitTestOutlet:(CGPoint)point
{

    CGPoint pointA = [bodyAOutlet convertToNodeSpaceAR:point];
    
    if(ccpLength(pointA) < 5.0f)
    {
        return 0;
    }
    
    
    CGPoint pointB = [bodyBOutlet convertToNodeSpaceAR:point];
    if(ccpLength(pointB) < 5.0f)
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
    bodyAOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];
    bodyBOutlet.spriteFrame = [CCSpriteFrame frameWithImageNamed:@"joint-outlet-unset.png"];
    
}

-(CGPoint)outletWorldPos:(int)idx
{
    if(idx == 0)
    {
        return [bodyAOutlet convertToWorldSpaceAR:CGPointZero];
    }
    else
    {
        return [bodyBOutlet convertToWorldSpaceAR:CGPointZero];
    }
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