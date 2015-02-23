//
//  CCBPhysicsTwoBodyJoint.h
//  SpriteBuilder
//
//  Created by John Twigg on 3/6/14.
//
//

#import "CCBPhysicsPivotJoint.h"

extern const float kMargin;
extern const float kEdgeRadius;

__attribute__((visibility("default")))
@interface CCBPhysicsTwoBodyJoint : CCBPhysicsPivotJoint
{
    CCSprite9Slice  * jointBody;
}

@property (nonatomic) CGPoint anchorB;


-(void)setupBody;
-(void)updateRenderBody;
-(float)localLength;
-(float)worldLength;
-(float)rotation;


@end
