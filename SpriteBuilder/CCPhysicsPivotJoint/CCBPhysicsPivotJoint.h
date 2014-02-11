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
}

@property CCNode * bodyA;
@property CCNode * bodyB;

@end

@interface CCBPhysicsPivotJoint : CCBPhysicsJoint
@property CGPoint * anchorA;

@end
