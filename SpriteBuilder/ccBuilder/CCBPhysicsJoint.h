//
//  CCBPhysicsJoint.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "cocos2d.h"

static const int kNumProperties = 6;
extern NSString *  dependantProperties[kNumProperties];


@interface CCBPhysicsJoint : CCNode
{
    CCNode * scaleFreeNode;
    
    CCSprite * bodyAOutlet;
    CCSprite * bodyBOutlet;
 
    NSUInteger bodyA_UUID;
    CCNode    *bodyA;
    
    NSUInteger bodyB_UUID;
    CCNode    *bodyB;
}

@property CCNode * bodyA;
@property CCNode * bodyB;

@property BOOL isSelected;//Is clears on Visit


-(int)hitTestOutlet:(CGPoint)point;
-(void)setOutletStatus:(int)idx value:(BOOL)value;
-(void)resetOutletStatus;
-(CGPoint)outletWorldPos:(int)idx;

-(void)removeObserverBody:(CCNode*)body;
-(void)addObserverBody:(CCNode*)body;

@end
