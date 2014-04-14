//
//  CCScaleFreeNode.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/19/14.
//
//

#import "CCScaleFreeNode.h"
#import "CCDirector.h"

@implementation CCScaleFreeNode

-(void)visit:(CCRenderer *)renderer parentTransform:(const GLKMatrix4 *)parentTransform
{
    CCNode * parent = self.parent;
    float scale = 1.0f;
    while (parent) {
        scale *= parent.scale;
        parent = parent.parent;
    }
    
    
    [self setScaleX:(hiddenScale * 1.0f/scale) ];
    [self setScaleY:(hiddenScale * 1.0f/scale) ];
    
    [super visit:renderer parentTransform:parentTransform];
}

-(void)setScale:(float)scale
{
    [super setScale:scale];
    hiddenScale = scale;
}

@end