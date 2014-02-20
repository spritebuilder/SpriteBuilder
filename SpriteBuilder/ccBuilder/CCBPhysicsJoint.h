//
//  CCBPhysicsJoint.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
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
