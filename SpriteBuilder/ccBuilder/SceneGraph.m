//
//  SceneGraph.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/21/14.
//
//

#import "SceneGraph.h"
#import "CCNode+NodeInfo.h"
#import "ProjectSettings.h"
#import "CCBReaderInternal.h"
#import "CCBFileUtil.h"
#import "CCBPCCBFile.h"

SceneGraph * gSceneGraph;

CCNode * findSceneRoot(CCNode * node)
{
	if(node.parent == nil)
		return node;
	
	if([[[node class] description] isEqualToString:@"CCBPCCBFile"])
	{
		return node;
	}
	
	return findSceneRoot(node.parent);
}

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

-(instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    self = [super init];
    if (self)
    {
        self.joints = [[SequencerJoints alloc] init];
        self.lightIcons = [[CCNode alloc] init];
    }
    return self;
}


typedef CCNode* (^FindUUIDBlock)(CCNode * node, NSUInteger uuid);

+(CCNode*)findUUID:(NSUInteger)uuid node:(CCNode*)node;
{
    if(uuid == 0)
        return nil;
    
    if(node.UUID == uuid)
        return node;
    
    for (CCNode * child in node.children) {
        CCNode * foundNode = [self findUUID:uuid node:child];
        
        if(foundNode)
            return foundNode;
        
    }
    return nil;

}

+(void)fixupReferences
{
	[gSceneGraph.joints fixupReferences];
	
	[CCBReaderInternal postDeserializationFixup:gSceneGraph.rootNode];
}


@end
