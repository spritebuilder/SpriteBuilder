//
//  CCNode+SKNode.h
//  SpriteBuilder
//
//  Created by Steffen Itterheim on 23/01/14.
//
//

#import "CCNode.h"

@interface CCNode (SKNode)

// SKNode
@property CGFloat alpha;
@property CGFloat speed;
@property CGFloat xScale;
@property CGFloat yScale;
@property CGFloat zRotation;
@property BOOL hidden;

// SKSpriteNode
@property CGFloat colorBlendFactor;
@property CGSize size;
@property CCSizeType sizeType;

@end
