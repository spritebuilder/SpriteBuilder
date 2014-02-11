//
//  SequencerJoints.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/7/14.
//
//

#import "SequencerJoints.h"
#import "CCBPPhysicsPivotJoint.h"

@implementation SequencerJoints

@dynamic all;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.node = [CCNode node];
    }
    
    return self;
}

-(NSArray*)all
{
    return [self.node children];
}

-(void)addJoint:(CCBPhysicsJoint *)joint
{
    [self.node addChild:joint];
}

@end
