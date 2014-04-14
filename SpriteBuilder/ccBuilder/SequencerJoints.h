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

-(id)serialize;
-(void)deserialize:(NSDictionary*)data;

-(void)addJoint:(CCBPhysicsJoint*)joint;

//When nodes from the scene graph are moved around, the joints need updating.
-(void)fixupReferences;



@end
