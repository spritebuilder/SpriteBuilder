//
//  CCNode+SKNode.h
//  SpriteBuilder
//
//  Created by Steffen Itterheim on 23/01/14.
//
//

#import "CCNode.h"

@interface CCNode (SKNode)

@property CGSize frameSize;
@property CGFloat alpha;
@property CGFloat speed;
@property CGFloat xScale;
@property CGFloat yScale;
@property CGFloat zRotation;
@property CCSizeType frameSizeType;
@property BOOL hidden;

@end
