//
//  CCBPhysicsPinJoint.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCBPhysicsPivotJoint.h"

@interface CCBPhysicsPinJoint : CCBPhysicsPivotJoint
{
    
}
@property (nonatomic) CGPoint anchorB;

@property (nonatomic) float minDistance;
@property (nonatomic) BOOL  minDistanceEnabled;
@property (nonatomic) float maxDistance;
@property (nonatomic) BOOL  maxDistanceEnabled;
@end
