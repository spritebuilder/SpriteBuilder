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

@interface CCBPLightNode ()
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

-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    _lightIcon.position = self.position;
    _lightIcon.rotation = self.rotation;

    [_lightIcon visit:renderer parentTransform:parentTransform];
    [super visit:renderer parentTransform:parentTransform];
}

@end
