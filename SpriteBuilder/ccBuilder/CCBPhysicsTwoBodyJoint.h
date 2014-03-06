//
//  CCBPhysicsTwoBodyJoint.h
//  SpriteBuilder
//
//  Created by John Twigg on 3/6/14.
//
//

#import "CCBPhysicsPivotJoint.h"

extern const float kMargin;

@interface CCBPhysicsTwoBodyJoint : CCBPhysicsPivotJoint
{
    
}

@property (nonatomic) CGPoint anchorB;

-(void)setupBody;
-(float)localLength;
-(float)worldLength;
-(float)rotation;
-(void)updateRenderBody;

@end
