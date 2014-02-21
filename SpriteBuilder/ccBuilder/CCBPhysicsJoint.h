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
@property BOOL isSelected;//Is clears on Visit


-(int)hitTestOutlet:(CGPoint)point;
-(void)setOutletStatus:(int)idx value:(BOOL)value;
-(void)resetOutletStatus;
-(CGPoint)outletWorldPos:(int)idx;

@end
