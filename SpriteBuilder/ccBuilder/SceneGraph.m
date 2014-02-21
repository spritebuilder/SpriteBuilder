//
//  SceneGraph.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/21/14.
//
//

#import "SceneGraph.h"

SceneGraph * gSceneGraph;

@implementation SceneGraph
@synthesize rootNode;

+(instancetype)instance{
    return gSceneGraph;
}

+(instancetype)setInstance:(SceneGraph*)instance
{
    gSceneGraph = instance;
    return gSceneGraph;
}


-(id)init
{
    self = [super init];
    if (self)
    {
        _joints = [[SequencerJoints alloc] init];
    }
    return self;
}


@end
