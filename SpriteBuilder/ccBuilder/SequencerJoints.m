//
//  SequencerJoints.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/7/14.
//
//

#import "SequencerJoints.h"
#import "CCBPhysicsPivotJoint.h"
#import "NodeInfo.h"
#import "CCNode+NodeInfo.h"

@implementation SequencerJoints

@dynamic all;

-(id)init
{
    self = [super init];
    if(self)
    {
        self.node = [CCNode node];
        self.node.name = @"SequencerJointsRoot";
        self.node.userObject = [[NodeInfo alloc] init];
    }
    
    return self;
}

-(void)deserialize:(NSDictionary*)data;
{
    self.node.locked = [data[@"locked"] boolValue];
    self.node.hidden = [data[@"hidden"] boolValue];
 
}

-(id)serialize
{
    return @{@"locked": @(self.node.locked),
             @"hidden": @(self.node.hidden)};
    
}

-(NSArray*)all
{
    return [self.node children];
}

-(void)addJoint:(CCBPhysicsJoint *)joint
{
    [self.node addChild:joint];
}

-(void)fixupReferences
{
    for (CCBPhysicsJoint * joint in self.all)
    {
        [joint fixupReferences];
        
    }
}

@end
