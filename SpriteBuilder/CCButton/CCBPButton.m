//
//  CCBPButton.m
//  SpriteBuilder
//
//  Created by Viktor on 9/25/13.
//
//

#import "CCBPButton.h"
#import "CCSpriteFrame.h"
#import "CCTexture.h"
#import "AppDelegate.h"
#import "InspectorController.h"

@implementation CCBPButton

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    self.userInteractionEnabled = NO;
    
    return self;
}


-(void)onSetSizeFromTexture
{
    CCSpriteFrame * spriteFrame = _backgroundSpriteFrames[@(CCControlStateNormal)];
    if(spriteFrame == nil)
        return;
    
    self.preferredSize = spriteFrame.texture.contentSize;
    
    [self willChangeValueForKey:@"preferredSize"];
    [self didChangeValueForKey:@"preferredSize"];
    [[InspectorController sharedController] refreshProperty:@"preferredSize"];
    
}

@end
