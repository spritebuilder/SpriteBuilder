//
//  CCBPNode.m
//  SpriteBuilder
//
//  Created by Viktor on 12/17/13.
//
//

#import "CCBPLightNode.h"
#import "CCDirector.h"
#import "CCDrawNode.h"
#import "CCSprite.h"
#import "SceneGraph.h"

@interface CCBPLightNode ()
@property (nonatomic, strong) SceneGraph *sceneGraph;
@property (nonatomic, strong) CCNode *lightIcon;
@end


@implementation CCBPLightNode

- (id) init
{
    if ((self = [super init]))
    {
        _lightIcon = [CCSprite spriteWithImageNamed:@"light-point.png"];
    }

    return self;
}

-(void)onEnter
{
    [super onEnter];
    
    self.sceneGraph = [SceneGraph instance];
    [self.sceneGraph.lightIcons addChild:_lightIcon];
}

-(void)onExit
{
    [self.sceneGraph.lightIcons removeChild:_lightIcon];
    self.sceneGraph = nil;

    [super onExit];
}

-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    CGPoint worldPos = [self convertToWorldSpace:self.anchorPoint];
    CGPoint localPos = [self.sceneGraph.lightIcons convertToNodeSpace:worldPos];
    _lightIcon.position = localPos;
    _lightIcon.rotation = self.rotation;

    [super visit:renderer parentTransform:parentTransform];
}

@end
