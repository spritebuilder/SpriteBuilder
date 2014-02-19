//
//  SequencerJoints.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/7/14.
//
//

#import <Foundation/Foundation.h>
#import "CocosScene.h"

@class CCBPhysicsJoint;

@interface SequencerJoints : NSObject
{
    CCNode * _node;
}

@property CCNode * node;
@property (readonly) NSArray * all;

-(void)addJoint:(CCBPhysicsJoint*)joint;
@end
