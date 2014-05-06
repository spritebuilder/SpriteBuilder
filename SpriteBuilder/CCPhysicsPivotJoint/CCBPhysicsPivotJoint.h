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
@property (nonatomic) BOOL  dampedSpringEnabled;
@property (nonatomic) float dampedSpringRestAngle;
@property (nonatomic) float dampedSpringStiffness;
@property (nonatomic) float dampedSpringDamping;


+(BOOL)nodeHasParent:(CCNode*)node parent:(CCNode*)parent;


@end
