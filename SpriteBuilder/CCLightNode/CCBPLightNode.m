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
        _pointLightImage = [CCTexture textureWithFile:@"light-point.png"];
        _directionalLightImage = [CCTexture textureWithFile:@"light-directional.png"];
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
        _lightIcon.texture = _pointLightImage;
    }
    else
    {
        _lightIcon.texture = _directionalLightImage;
    }
}

@end
