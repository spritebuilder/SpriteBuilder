//
//  CCBPNode.h
//  SpriteBuilder
//
//  Created by Viktor on 12/17/13.
//
//

#import "CCLabelTTF.h"
#import "CCNode+SKNode.h"

@interface CCBPluginSKLabelNode : CCLabelTTF
SKNODE_COMPATIBILITY_HEADER

@property (nonatomic) NSString* text;

@end
