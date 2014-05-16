//
//  CCBPPhysicsPivotJoint.h
//  SpriteBuilder
//
//  Created by John Twigg.
//
//

#import "CCBPhysicsJoint.h"


typedef enum
{
    eLayoutButtonNone = -1,
    eLayoutButtonSpring = 0,
    eLayoutButtonLimit,
    eLayoutButtonRatchet,
    eLayoutButtonMax
    
} eLayoutButtonType;

@interface CCBPhysicsPivotJoint : CCBPhysicsJoint
{
}

@property (nonatomic) CGPoint anchorA;

@property (nonatomic) eLayoutButtonType layoutType;
@property (nonatomic) float referenceAngle;

//Spring joint properties
@property (nonatomic) BOOL  dampedSpringEnabled;
@property (nonatomic) float dampedSpringRestAngle;
@property (nonatomic) float dampedSpringStiffness;
@property (nonatomic) float dampedSpringDamping;

//Limit joint properties
@property (nonatomic) BOOL  limitEnabled;
@property (nonatomic) float limitMin;
@property (nonatomic) float limitMax;

//Motor proprties.
@property (nonatomic) BOOL  motorEnabled;
@property (nonatomic) BOOL  motorMaxForceEnabled;
@property (nonatomic) float motorMaxForce;
@property (nonatomic) float motorRate;

//Ratchet Properties.
@property (nonatomic) BOOL  ratchetEnabled;
@property (nonatomic) float ratchetValue;
@property (nonatomic) float ratchetPhase;



+(BOOL)nodeHasParent:(CCNode*)node parent:(CCNode*)parent;


@end
