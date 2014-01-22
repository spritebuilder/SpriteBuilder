//
//  SKNode.h
//  SpriteBuilder
//
//  Created by Steffen Itterheim on 22/01/14.
//
//

#import "CCNode.h"

@interface SKNode : CCNode

@property CGSize frameSize;
@property CGFloat alpha;
@property CGFloat speed;
@property CGFloat xScale;
@property CGFloat yScale;
@property CGFloat zRotation;
@property CCSizeType frameSizeType;
@property BOOL hidden;

@end
