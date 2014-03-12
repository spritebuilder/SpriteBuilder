//
//  CCBPNode.m
//  SpriteBuilder
//
//  Created by Viktor on 12/17/13.
//
//

#import "CCBPluginSBButtonNode.h"

@implementation CCBPluginSBButtonNode
SKNODE_COMPATIBILITY_CODE

-(id) init
{
    self = [super init];
    if (!self) return NULL;
    
    self.userInteractionEnabled = NO;
    
    return self;
}

@end
