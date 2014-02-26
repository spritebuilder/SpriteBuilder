//
//  SceneGraph.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/21/14.
//
//

#import "SceneGraph.h"
#import "CCNode+NodeInfo.h"

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


typedef CCNode* (^FindUUIDBlock)(CCNode * node, NSUInteger uuid);

+(CCNode*)findUUID:(NSUInteger)uuid rootNode:(CCNode*)rootNode
{
    if(uuid == 0)
        return nil;
    
    __block FindUUIDBlock findUUIDT;
    //Recursive.
    findUUIDT = ^CCNode*(CCNode * node, NSUInteger uuid)
    {
        if(node.UUID == uuid)
            return node;
        
        for (CCNode * child in node.children) {
            CCNode * foundNode = findUUIDT(child,uuid);
            
            if(foundNode)
                return foundNode;
            
        }
        return nil;
    };
    
    CCNode * foundNode = findUUIDT(rootNode,uuid);
    
    return foundNode;
}


@end
