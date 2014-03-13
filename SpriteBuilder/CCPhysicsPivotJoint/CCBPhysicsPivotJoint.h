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

+(BOOL)nodeHasParent:(CCNode*)node parent:(CCNode*)parent;

@end
