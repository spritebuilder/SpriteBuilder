//
//  CCBPPhysicsPivotJoint.h
//  SpriteBuilder
//
//  Created by John Twigg.
//
//

#import "CCBPhysicsJoint.h"



@interface CCBPhysicsPivotJoint : CCBPhysicsJoint
{
}

@property (nonatomic) CGPoint anchorA;
@property (nonatomic) BOOL dampedSpringEnabled;
@property (nonatomic) float restAngle;
@property (nonatomic) float stiffness;
@property (nonatomic) float damping;


+(BOOL)nodeHasParent:(CCNode*)node parent:(CCNode*)parent;


@end
