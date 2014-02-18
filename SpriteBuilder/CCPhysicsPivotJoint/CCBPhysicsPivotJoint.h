//
//  CCBPPhysicsPivotJoint.h
//  SpriteBuilder
//
//  Created by John Twigg.
//
//

#import "cocos2d.h"

@interface CCBPhysicsJoint : CCNode
{
    CCNode * scaleFreeNode;

    CCSprite * bodyAOutlet;
    CCSprite * bodyBOutlet;
   
    CCNode * bodyA;
    CCNode * bodyB;
    
}

@property CCNode * bodyA;
@property CCNode * bodyB;


-(int)hitTestOutlet:(CGPoint)point;
-(void)setOutletStatus:(int)idx value:(BOOL)value;
-(void)resetOutletStatus;
-(CGPoint)outletPos:(int)idx;

@end

@interface CCBPhysicsPivotJoint : CCBPhysicsJoint
{
    CGPoint anchorA;
}

@property CGPoint anchorA;

@end
