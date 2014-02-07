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
    
}

@property CCNode * bodyA;
@property CCNode * bodyB;


@end

@interface CCBPPhysicsPivotJoint : CCBPhysicsJoint
@property CGPoint * anchorA;

@end
