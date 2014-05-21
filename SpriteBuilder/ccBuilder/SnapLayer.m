//
//  SnapLayer.m
//  SpriteBuilder
//
//  Created by Michael Daniels on 4/8/14.
//
//

#import "SnapLayer.h"
#import "AppDelegate.h"
#import "CocosScene.h"
#import "CCNode+PositionExtentions.h"
#import "PositionPropertySetter.h"
#import "SnapLayerKeys.h"

#define kSnapLayerSensitivity   4

@interface SnapLayer() {
    float sensitivity;
    float gridSize;
    CGPoint lastPoint;
    BOOL drag;
}

@property (nonatomic, strong) AppDelegate *appDelegate;

@property (nonatomic, strong) NSMutableSet *verticalSnapLines;
@property (nonatomic, strong) NSMutableSet *horizontalSnapLines;

@end

@implementation SnapLayer

@synthesize appDelegate;

@synthesize verticalSnapLines;
@synthesize horizontalSnapLines;

#pragma mark - Setup

- (id)init
{
    if (self = [super init]) {
        [self setup];
        lastPoint = ccp(0,0);
        drag      = false;
    }
    return self;
}

- (void)setup {
    appDelegate = [AppDelegate appDelegate];
    
    sensitivity = kSnapLayerSensitivity;

    verticalSnapLines   = [NSMutableSet new];
    horizontalSnapLines = [NSMutableSet new];

}

#pragma mark - Memory Management

- (void)dealloc {
    [NSEvent removeMonitor:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Drawing

- (void)drawLines {
    
    if(!drag) return;
    
    [self removeAllChildren];
    
    CocosScene *cs = [CocosScene cocosScene];
    
    CGRect viewRect = CGRectZero;
    viewRect.size = winSize;
    
    for(CCNode *sNode in appDelegate.selectedNodes) {

        if(sNode != cs.rootNode) {
            
            for(NSNumber *y in horizontalSnapLines) {
                CGPoint viewPos = ccp(0, y.floatValue);
                
                if (CGRectContainsPoint(viewRect, viewPos))
                {
                    CCSprite9Slice* sprtGuide = [CCSprite9Slice spriteWithImageNamed:@"ruler-guide.png"];
                    sprtGuide.contentSizeType = CCSizeTypeMake(CCSizeUnitPoints, CCSizeUnitUIPoints);
                    sprtGuide.contentSize = CGSizeMake(winSize.width, 2);
                    sprtGuide.anchorPoint = ccp(0, 0.5f);
                    sprtGuide.position = ccp(roundf(viewPos.x),roundf(viewPos.y));
                    [sprtGuide setColor:[CCColor redColor]];
                    [self addChild:sprtGuide];
                    
                }

            }
            
            for(NSNumber *x in verticalSnapLines) {
                CGPoint viewPos = ccp(x.floatValue, 0);
                
                if (CGRectContainsPoint(viewRect, viewPos))
                {
                    CCSprite9Slice* sprtGuide = [CCSprite9Slice spriteWithImageNamed:@"ruler-guide.png"];
                    sprtGuide.contentSizeType = CCSizeTypeMake(CCSizeUnitPoints, CCSizeUnitUIPoints);
                    sprtGuide.contentSize = CGSizeMake(winSize.height, 2);
                    sprtGuide.anchorPoint = ccp(0, 0.5f);
                    sprtGuide.rotation = -90;
                    sprtGuide.position = ccp(roundf(viewPos.x),roundf(viewPos.y));
                    [sprtGuide setColor:[CCColor redColor]];
                    [self addChild:sprtGuide];

                }
                
            }
            
        }
    }
}

- (void) updateWithSize:(CGSize)ws stageOrigin:(CGPoint)so zoom:(float)zm
{
    if (!self.visible) return;
    
    if (CGSizeEqualToSize(ws, winSize)
        && CGPointEqualToPoint(so, stageOrigin)
        && zm == zoom)
    {
        return;
    }
    
    // Store values
    winSize     = ws;
    stageOrigin = so;
    zoom        = zm;
    
    [self drawLines];
}


#pragma mark - Snap Lines Methods

- (void)updateLines {
    [self findSnappedLines];
    [self drawLines];
}

- (void)findSnappedLines {
    
    [verticalSnapLines removeAllObjects];
    [horizontalSnapLines removeAllObjects];
    
    for(CCNode *sNode in appDelegate.selectedNodes) {
        
        if(sNode && sNode.parent) {
            
            // Try and snap with all children of the selected node's parent
            NSMutableArray *nodesToSearchForSnapping = [NSMutableArray arrayWithArray:sNode.parent.children];
            for(CCNode *node in nodesToSearchForSnapping) {
                
                // Ignore the selected node
                if(node != sNode) {
                    
                    NSPoint sPoint = [sNode convertToWorldSpace:sNode.anchorPointInPoints];
                    NSPoint point = [node convertToWorldSpace:node.anchorPointInPoints];
                    
                    // Snap lines from anchorPoint
                    if(abs(sPoint.x - point.x) < 1) {
                        [self addVerticalSnapLine:sPoint.x node:sNode];
                    }
                    if(abs(sPoint.y - point.y) < 1) {
                        [self addHorizontalSnapLine:sPoint.y node:sNode];
                    }
                    
                    // Snap lines from center
                    if(abs(sNode.centerXInPoints - node.centerXInPoints) < 1) {
                         [self addVerticalSnapLine:sNode.centerXInPoints node:sNode];
                    }
										if(abs(sNode.centerYInPoints - node.centerYInPoints) < 1) {
                        [self addHorizontalSnapLine:sNode.centerYInPoints node:sNode];
                    }
                    
                    // Snap lines for opposite sides
                    if(abs(sNode.leftInPoints - node.rightInPoints) < 1) {
                        [self addVerticalSnapLine:sNode.leftInPoints node:sNode];
                    }
                    if(abs(sNode.rightInPoints - node.leftInPoints) < 1) {
                        [self addVerticalSnapLine:sNode.rightInPoints node:sNode];
                        
                    }
                    if(abs(sNode.topInPoints - node.bottomInPoints) < 1) {
                        [self addHorizontalSnapLine:sNode.topInPoints node:sNode];
                    }
                    if(abs(sNode.bottomInPoints - node.topInPoints) < 1) {
                        [self addHorizontalSnapLine:sNode.bottomInPoints node:sNode];
                    }
                    
                    // Snap lines for same sides
                    if(abs(sNode.leftInPoints - node.leftInPoints) < 1) {
                        [self addVerticalSnapLine:sNode.leftInPoints node:sNode];
                    }
                    if(abs(sNode.rightInPoints - node.rightInPoints) < 1) {
                        [self addVerticalSnapLine:sNode.rightInPoints node:sNode];
                    }
                    if(abs(sNode.topInPoints - node.topInPoints) < 1) {
                        [self addHorizontalSnapLine:sNode.topInPoints node:sNode];
                    }
                    if(abs(sNode.bottomInPoints - node.bottomInPoints) < 1) {
                        [self addHorizontalSnapLine:sNode.bottomInPoints node:sNode];
                    }
                }
            }
            
            
            // Snap lines from center of sNode to center of parent
            if(abs(sNode.centerXInPoints - sNode.parent.centerXInPoints ) < 1) {
                [self addVerticalSnapLine:sNode.parent.centerXInPoints node:sNode];
            }
            if(abs(sNode.centerYInPoints - sNode.parent.centerYInPoints) < 1) {
                [self addHorizontalSnapLine:sNode.parent.centerYInPoints node:sNode];
            }
            
            // Snap to sides to edge of parent
            if(abs(sNode.leftInPoints - sNode.parent.leftInPoints) < sensitivity) {
                [self addVerticalSnapLine:sNode.parent.leftInPoints node:sNode];
            } else if(abs(sNode.rightInPoints - sNode.parent.rightInPoints) < sensitivity) {
                [self addVerticalSnapLine:sNode.parent.rightInPoints node:sNode];
            }
            if(abs(sNode.topInPoints - sNode.parent.topInPoints) < sensitivity) {
                [self addHorizontalSnapLine:sNode.parent.topInPoints node:sNode];
            } else if(abs(sNode.bottomInPoints - sNode.parent.bottomInPoints) < sensitivity) {
                [self addHorizontalSnapLine:sNode.parent.bottomInPoints node:sNode];
            }
						
            nodesToSearchForSnapping = nil;
        }
    }
}

-(void) addVerticalSnapLine:(float)x node:(CCNode*)node {
    [verticalSnapLines addObject:[NSNumber numberWithFloat:roundf(x)]];
}

-(void) addHorizontalSnapLine:(float)y node:(CCNode*)node {
    [horizontalSnapLines addObject:[NSNumber numberWithFloat:roundf(y)]];
}

#pragma mark - Snapping Methods

- (void)snapIfNeeded {
    
    for(CCNode *sNode in appDelegate.selectedNodes) {
        
        if(sNode && sNode.parent) {
            
            CGPoint currentLocationInPoints = sNode.positionInPoints;
            
            // Try and snap with all children of the selected node's parent
            NSMutableArray *nodesToSearchForSnapping = [NSMutableArray arrayWithArray:sNode.parent.children];
            
            for(CCNode *node in nodesToSearchForSnapping) {
                
                if(node != sNode) { // Ignore the selected node
                    NSPoint sPoint = [sNode convertToWorldSpace:sNode.anchorPointInPoints];
                    NSPoint point = [node convertToWorldSpace:node.anchorPointInPoints];
                    
                    // Snap from anchorPoint
                    if(abs(sPoint.x - point.x) < sensitivity) {
                        sPoint.x = point.x;
                    }
										if(abs(sPoint.y - point.y) < sensitivity) {
                        sPoint.y = point.y;
                    }
                    sNode.position = [sNode convertPositionFromPoints:[sNode.parent convertToNodeSpace:sPoint] type:self.positionType];
                    
                    // Snap from center
                    if(abs(sNode.centerXInPoints - node.centerXInPoints) < sensitivity) {
                        sNode.centerXInPoints = node.centerXInPoints;
                    }
										if(abs(sNode.centerYInPoints - node.centerYInPoints) < sensitivity) {
                        sNode.centerYInPoints = node.centerYInPoints;
                    }
                    
                    // Snap to opposite sides
                    if(abs(sNode.leftInPoints - node.rightInPoints) < sensitivity) {
                        sNode.leftInPoints = node.rightInPoints;
                    } else if(abs(sNode.rightInPoints - node.leftInPoints) < sensitivity) {
                        sNode.rightInPoints = node.leftInPoints;
                    }
                    if(abs(sNode.topInPoints - node.bottomInPoints) < sensitivity) {
                        sNode.topInPoints = node.bottomInPoints;
                    } else if(abs(sNode.bottomInPoints - node.topInPoints) < sensitivity) {
                        sNode.bottomInPoints = node.topInPoints;
                    }
                    
                    // Snap to same sides
                    if(abs(sNode.leftInPoints - node.leftInPoints) < sensitivity) {
                        sNode.leftInPoints = node.leftInPoints;
                    } else if(abs(sNode.rightInPoints - node.rightInPoints) < sensitivity) {
                        sNode.rightInPoints = node.rightInPoints;
                    }
                    if(abs(sNode.topInPoints - node.topInPoints) < sensitivity) {
                        sNode.topInPoints = node.topInPoints;
                    } else if(abs(sNode.bottomInPoints - node.bottomInPoints) < sensitivity) {
                        sNode.bottomInPoints = node.bottomInPoints;
                    }
                    
                }
            }
            
            
            // Center parent
            if(abs(sNode.centerXInPoints - sNode.parent.centerXInPoints ) < sensitivity) {
                sNode.centerXInPoints = sNode.parent.centerXInPoints;
            }
            if(abs(sNode.centerYInPoints - sNode.parent.centerYInPoints) < sensitivity) {
                sNode.centerYInPoints = sNode.parent.centerYInPoints;
            }
            
            // Snap to sides to edge of parent.
            if(abs(sNode.leftInPoints - sNode.parent.leftInPoints) < sensitivity) {
                sNode.leftInPoints = sNode.parent.leftInPoints;
            } else if(abs(sNode.rightInPoints - sNode.parent.rightInPoints) < sensitivity) {
                sNode.rightInPoints = sNode.parent.rightInPoints;
            }
            if(abs(sNode.topInPoints - sNode.parent.topInPoints) < sensitivity) {
                sNode.topInPoints = sNode.parent.topInPoints;
            } else if(abs(sNode.bottomInPoints - sNode.parent.bottomInPoints) < sensitivity) {
                sNode.bottomInPoints = sNode.parent.bottomInPoints;
            }
            
            nodesToSearchForSnapping = nil;
            CGPoint difference = ccpSub(currentLocationInPoints, sNode.positionInPoints);
            for(CCNode *node in appDelegate.selectedNodes) {
                if(node != sNode) {
                    NSPoint point = ccpSub(node.positionInPoints, difference);
                    point = [self convertPositionFromPoints:point type:self.positionType];
                    node.position = point;
                }
            }
        }
    }
    
    
    [self updateLines];
    [appDelegate refreshProperty:@"position"];
}

#pragma mark - Mouse Events

- (BOOL) mouseDown:(CGPoint)pt event:(NSEvent*)event
{
    if (!self.visible) return NO;
    
    lastPoint = pt;
    
    return YES;
}

- (BOOL) mouseDragged:(CGPoint)pt event:(NSEvent*)event
{
    if (!self.visible) return NO;

    if (event.modifierFlags & NSCommandKeyMask) {
        [self removeAllChildren];
        return NO;
    }
    
    if(CGPointEqualToPoint(lastPoint, pt)) return NO;
    
    drag = YES;
    
    [self snapIfNeeded];
    
    return YES;
}

- (BOOL) mouseUp:(CGPoint)pt event:(NSEvent*)event
{
    drag = NO;
    if (!self.visible) return NO;
    
    [self removeAllChildren];

    return YES;
}

@end
