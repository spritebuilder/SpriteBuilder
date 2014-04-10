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

@interface SceneGraph : NSObject
{
    CCNode* rootNode;
    
}

+(instancetype) instance;
+(instancetype)setInstance:(SceneGraph*)instance;
+(CCNode*)findUUID:(NSUInteger)uuid node:(CCNode*)node;

@property (nonatomic,strong) CCNode* rootNode;
@property (nonatomic,strong) SequencerJoints * joints;

@end
