//
//  SnapLayer.h
//  SpriteBuilder
//
//  Created by Michael Daniels on 4/8/14.
//
//

#import "CCNode.h"

@interface SnapLayer : CCNode

- (BOOL) mouseDown:(CGPoint)pt event:(NSEvent*)event;
- (BOOL) mouseDragged:(CGPoint)pt event:(NSEvent*)event;
- (BOOL) mouseUp:(CGPoint)pt event:(NSEvent*)event;
- (void)updateLines;

@property (nonatomic) CCNode *selectedNode;

@end
