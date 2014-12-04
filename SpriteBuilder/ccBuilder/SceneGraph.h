//
//  SceneGraph.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/21/14.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "SequencerJoints.h"

@class ProjectSettings;

//This returns the scene root OR, if its a CCB file, it find the root CCB File.
CCNode * findSceneRoot(CCNode * node);

@interface SceneGraph : NSObject
{
    CCNode* rootNode;
    
}

-(id)initWithProjectSettings:(ProjectSettings *)projectSettings;

+(instancetype) instance;
+(instancetype)setInstance:(SceneGraph*)instance;
+(CCNode*)findUUID:(NSUInteger)uuid node:(CCNode*)node;
+(void)fixupReferences;

@property (nonatomic,strong) CCNode* rootNode;
@property (nonatomic,strong) SequencerJoints * joints;
@property (nonatomic,strong) CCNode* lightIcons;

@end
