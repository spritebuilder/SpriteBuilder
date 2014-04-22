//
//  CCBPPhysicsSpringJoint.h
//  SpriteBuilder
//
//  Created by John Twigg.
//
//

#import "CCBPhysicsTwoBodyJoint.h"



@interface CCBPhysicsSpringJoint : CCBPhysicsTwoBodyJoint
{
}

@property (nonatomic) BOOL  restLengthEnabled;
@property (nonatomic) float restLength;
@property (nonatomic) float damping;
@property (nonatomic) float stiffness;



@end
