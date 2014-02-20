//
//  CCBPPhysicsPivotJoint.h
//  SpriteBuilder
//
//  Created by John Twigg.
//
//

#import "CCBPhysicsJoint.h"


static const int kNumProperties = 6;
extern NSString *  dependantProperties[kNumProperties];

@interface CCBPhysicsPivotJoint : CCBPhysicsJoint
{
    CGPoint anchorA;
}

@property CGPoint anchorA;

@end
