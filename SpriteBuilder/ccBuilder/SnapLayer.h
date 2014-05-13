//
//  SnapLayer.h
//  SpriteBuilder
//
//  Created by Michael Daniels on 4/8/14.
//
//

#import "CCNode.h"

@interface SnapLayer : CCNode {
    
    CGSize winSize;
    CGPoint stageOrigin;
    float zoom;
}

- (BOOL) mouseDown:(CGPoint)pt event:(NSEvent*)event;
- (BOOL) mouseDragged:(CGPoint)pt event:(NSEvent*)event;
- (BOOL) mouseUp:(CGPoint)pt event:(NSEvent*)event;
- (void) updateLines;
- (void) updateWithSize:(CGSize)ws stageOrigin:(CGPoint)so zoom:(float)zm;

@property (nonatomic) CCNode *selectedNode;

@end
