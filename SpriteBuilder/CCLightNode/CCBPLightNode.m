//
//  CCBPLightNode.m
//  SpriteBuilder
//
//  Created by Thayer on 11/20/14.
//
//

#import "CCBPLightNode.h"
#import "CCDirector.h"
#import "CCDrawNode.h"
#import "CCSprite.h"
#import "SceneGraph.h"
#import "NodeInfo.h"
#import "CCNode+NodeInfo.h"
#import "ForceResolution.h"


@interface CCBPLightNode ()
@property (nonatomic, strong) SceneGraph *sceneGraph;
@property (nonatomic, strong) CCTexture *pointLightImage;
@property (nonatomic, strong) CCTexture *directionalLightImage;
@property (nonatomic, strong) CCSprite *lightIcon;
@end


@implementation CCBPLightNode

- (id) init
{
    if ((self = [super init]))
    {
        _sceneGraph = nil;
        _pointLightImage = [CCTexture textureWithFile:@"light-point.png" contentScale:[CCTexture SBWidgetScale]];
        _directionalLightImage = [CCTexture textureWithFile:@"light-directional.png" contentScale:[CCTexture SBWidgetScale]];
        _lightIcon = [CCSprite spriteWithImageNamed:@"light-point.png" contentScale:[CCTexture SBWidgetScale]];
        _lightIcon.userObject = [[NodeInfo alloc] init];
    }

    return self;
}

-(void)postDeserializationFixup
{
    [super postDeserializationFixup];

    if (!self.sceneGraph)
    {
        self.sceneGraph = [SceneGraph instance];
        NSAssert(self.sceneGraph, @"Expected a valid SceneGraph instance and didn't find one.");
        [self.sceneGraph.lightIcons addChild:_lightIcon];
    }
}

-(void)onEnter
{
    [super onEnter];
    
    if (!self.sceneGraph)
    {
        self.sceneGraph = [SceneGraph instance];
        NSAssert(self.sceneGraph, @"Expected a valid SceneGraph instance and didn't find one.");
        [self.sceneGraph.lightIcons addChild:_lightIcon];
    }
}

-(void)onExit
{
    if (self.sceneGraph)
    {
        [self.sceneGraph.lightIcons removeChild:_lightIcon];
        self.sceneGraph = nil;
    }
    
    [super onExit];
}

-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    CGPoint worldPos = [self convertToWorldSpace:self.anchorPoint];
    CGPoint localPos = [self.sceneGraph.lightIcons convertToNodeSpace:worldPos];
    self.lightIcon.position = localPos;
    self.lightIcon.rotation = self.rotation;

    [super visit:renderer parentTransform:parentTransform];
}

- (BOOL)hidden
{
    return self.lightIcon.hidden;
}

- (void)setHidden:(BOOL)hidden
{
    self.lightIcon.hidden = hidden;
}

- (void)setVisible:(BOOL)visible
{
    [super setVisible:visible];
    self.lightIcon.visible = visible;
}

-(void)setColor:(CCColor *)color
{
    [super setColor:color];
    self.lightIcon.color = color;
}

-(void)setType:(CCLightType)type
{
    [super setType:type];
    if (type == CCLightPoint)
    {
        self.lightIcon.texture = _pointLightImage;
    }
    else
    {
        self.lightIcon.texture = _directionalLightImage;
    }
}

@end
