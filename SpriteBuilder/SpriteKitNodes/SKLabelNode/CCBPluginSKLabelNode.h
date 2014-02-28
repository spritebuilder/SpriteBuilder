//
//  CCBPNode.h
//  SpriteBuilder
//
//  Created by Viktor on 12/17/13.
//
//

#import "CCLabelTTF.h"
#import "CCNode+SKNode.h"

typedef NS_ENUM(NSInteger, SKLabelVerticalAlignmentMode) {
	SKLabelVerticalAlignmentModeBaseline    = 0,
	SKLabelVerticalAlignmentModeCenter      = 1,
	SKLabelVerticalAlignmentModeTop         = 2,
	SKLabelVerticalAlignmentModeBottom      = 3,
};

typedef NS_ENUM(NSInteger, SKLabelHorizontalAlignmentMode) {
	SKLabelHorizontalAlignmentModeCenter    = 0,
	SKLabelHorizontalAlignmentModeLeft      = 1,
	SKLabelHorizontalAlignmentModeRight     = 2,
};

@interface CCBPluginSKLabelNode : CCLabelTTF
SKNODE_COMPATIBILITY_HEADER

@property (nonatomic) NSString* text;
@property (nonatomic) NSInteger verticalAlignmentMode;
@property (nonatomic) NSInteger horizontalAlignmentMode;

@end
