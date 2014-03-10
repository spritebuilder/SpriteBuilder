//
//  CCBPhysicsPinJoint.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCBPhysicsTwoBodyJoint.h"

@interface CCBPhysicsPinJoint : CCBPhysicsTwoBodyJoint
{
    
}


@property (nonatomic) float minDistance;
@property (nonatomic) BOOL  minDistanceEnabled;
@property (nonatomic) float maxDistance;
@property (nonatomic) BOOL  maxDistanceEnabled;
@end
