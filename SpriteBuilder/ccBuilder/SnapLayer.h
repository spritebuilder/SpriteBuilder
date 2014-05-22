//
//  SnapLayer.h
//  SpriteBuilder
//
//  Created by Michael Daniels on 4/8/14.
//  Extended by SpriteBuilder Authors May 2014
//
//

#import "CCNode.h"

enum
{
    kCCBSnapOrientationHorizontal,
    kCCBSnapOrientationVertical
};

enum
{
    kCCBSnapTypeDefault,
};

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
