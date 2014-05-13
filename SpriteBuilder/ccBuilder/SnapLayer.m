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
    
    [self removeAllChildrenWithCleanup:YES];
    
    CocosScene *cs = [CocosScene cocosScene];
    
    CGRect viewRect = CGRectZero;
    viewRect.size = winSize;
    
    for(CCNode *sNode in appDelegate.selectedNodes) {

        if(sNode != cs.rootNode) {
            
            for(NSNumber *x in horizontalSnapLines) {
                
                CGPoint viewPos = [cs convertToViewSpace:ccp(0,[x floatValue])];
                viewPos.x = 0;
                
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
            
            
            for(NSNumber *y in verticalSnapLines) {
                
                CGPoint viewPos = [cs convertToViewSpace:ccp([y floatValue],0)];
                viewPos.y = 0;
                
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

- (CGPoint)getStagePointWithPoint:(CGPoint)point forNode:(CCNode *)node {
    CGPoint offset = point;
    CocosScene *cs = [CocosScene cocosScene];
	for (CCNode *parent = node.parent; parent != nil && parent != cs.rootNode; parent = parent.parent) {
        offset.x = offset.x * parent.scaleXInPoints + parent.positionInPoints.x - (parent.contentSizeInPoints.width * parent.anchorPoint.x) * parent.scaleXInPoints;
        offset.y = offset.y * parent.scaleYInPoints + parent.positionInPoints.y - (parent.contentSizeInPoints.height * parent.anchorPoint.y) * parent.scaleYInPoints;
    }
    return offset;
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
            
            CocosScene* cs = [CocosScene cocosScene];
            
            // Try and snap with all children of the selected node's parent
            NSMutableArray *nodesToSearchForSnapping = [NSMutableArray arrayWithArray:sNode.parent.children];
            for(CCNode *node in nodesToSearchForSnapping) {
                
                // Ignore the selected node
                if(node != sNode) {
                    
                    NSPoint point = [sNode convertPositionToPoints:sNode.position type:sNode.positionType];
                    NSPoint nPoint = [sNode convertPositionToPoints:node.position type:node.positionType];
                    
                    // Snap lines from anchorPoint
                    if(point.x == nPoint.x) {
                        [verticalSnapLines addObject:[NSNumber numberWithFloat:roundf(point.x)]];
                    }
                    if(point.y == nPoint.y) {
                        [horizontalSnapLines addObject:[NSNumber numberWithFloat:roundf(point.y)]];
                    }
                    
                    // Snap lines from center
                    if(abs((sNode.leftInPoints + (sNode.contentSizeInPoints.width / 2) * sNode.scaleXInPoints) - (node.leftInPoints + node.contentSizeInPoints.width / 2)) < 1) {
                        [verticalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.leftInPoints + (sNode.contentSizeInPoints.width / 2) * sNode.scaleXInPoints)]];
                    } if(abs((sNode.bottomInPoints + (sNode.contentSizeInPoints.height / 2) * sNode.scaleYInPoints) - (node.bottomInPoints + node.contentSizeInPoints.height / 2)) < 1) {
                        [horizontalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.bottomInPoints + (sNode.contentSizeInPoints.height / 2) * sNode.scaleYInPoints)]];
                    }
                    
                    // Snap lines for opposite sides
                    if(abs(sNode.leftInPoints - node.rightInPoints) < 1) {
                        [verticalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.leftInPoints)]];
                    }
                    if(abs(sNode.rightInPoints - node.leftInPoints) < 1) {
                        [verticalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.rightInPoints)]];
                    }
                    if(abs(sNode.topInPoints - node.bottomInPoints) < 1) {
                        [horizontalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.topInPoints)]];
                    }
                    if(abs(sNode.bottomInPoints - node.topInPoints) < 1) {
                        [horizontalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.bottomInPoints)]];
                    }
                    
                    // Snap lines for same sides
                    if(abs(sNode.leftInPoints - node.leftInPoints) < 1) {
                        [verticalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.leftInPoints)]];
                    }
                    if(abs(sNode.rightInPoints - node.rightInPoints) < 1) {
                        [verticalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.rightInPoints)]];
                    }
                    if(abs(sNode.topInPoints - node.topInPoints) < 1) {
                        [horizontalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.topInPoints)]];
                    }
                    if(abs(sNode.bottomInPoints - node.bottomInPoints) < 1) {
                        [horizontalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.bottomInPoints)]];
                    }
                }
            }
            
            /*
            // Snap lines from center of sNode to center of rootNode
            if(abs((sNode.leftInPoints + (sNode.contentSizeInPoints.width / 2) * sNode.scaleXInPoints) - (sNode.parent.contentSizeInPoints.width / 2) ) < 1) {
                [verticalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.parent.contentSizeInPoints.width / 2)]];
            }
            if(abs((sNode.bottomInPoints + (sNode.contentSizeInPoints.height / 2) * sNode.scaleYInPoints) - (sNode.parent.contentSizeInPoints.height / 2)) < 1) {
                [horizontalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.parent.contentSizeInPoints.height / 2)]];
            }
            
            // Snap to sides to edge of view
            if(abs(sNode.leftInPoints) < sensitivity) {
                [verticalSnapLines addObject:[NSNumber numberWithFloat:0]];
            } else if(abs(sNode.rightInPoints - sNode.parent.contentSizeInPoints.width) < sensitivity) {
                [verticalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.parent.contentSizeInPoints.width)]];
            }
            if(abs(sNode.topInPoints - sNode.parent.contentSizeInPoints.height) < sensitivity) {
                [horizontalSnapLines addObject:[NSNumber numberWithFloat:roundf(sNode.parent.contentSizeInPoints.height)]];
            } else if(abs(sNode.bottomInPoints) < sensitivity) {
                [horizontalSnapLines addObject:[NSNumber numberWithFloat:0]];
            }
            */
            
            cs = nil;
            nodesToSearchForSnapping = nil;
        }
    }
}

#pragma mark - Snapping Methods

- (void)snapIfNeeded {

        for(CCNode *sNode in appDelegate.selectedNodes) {
            
            if(sNode && sNode.parent) {
                
                CGPoint currentLocationInPoints = sNode.positionInPoints;
                CocosScene* cs = [CocosScene cocosScene];
                
                // Try and snap with all children of the selected node's parent
                NSMutableArray *nodesToSearchForSnapping = [NSMutableArray arrayWithArray:sNode.parent.children];
                
                
                
                for(CCNode *node in nodesToSearchForSnapping) {
                    
                    if(node != sNode) { // Ignore the selected node
                        NSPoint point = [sNode convertPositionToPoints:sNode.position type:sNode.positionType];
                        NSPoint nPoint = [sNode convertPositionToPoints:node.position type:node.positionType];
                        
                        float newX = point.x;
                        float newY = point.y;
                        
                        // Snap from anchorPoint
                        if(abs(point.x - nPoint.x) < sensitivity) {
                            newX = nPoint.x;
                        } if(abs(point.y - nPoint.y) < sensitivity) {
                            newY = nPoint.y;
                        }
                        CGPoint pointToSnapFromAnchorPoint = [sNode convertPositionFromPoints:NSMakePoint(newX, newY) type:sNode.positionType];
                        appDelegate.selectedNode.position = pointToSnapFromAnchorPoint;
                        
                        // Snap from center
                        if(abs((sNode.leftInPoints + (sNode.contentSizeInPoints.width / 2) * sNode.scaleXInPoints) - (node.leftInPoints + node.contentSizeInPoints.width / 2)) < sensitivity) {
                            sNode.leftInPoints = node.leftInPoints + node.contentSizeInPoints.width / 2 - (sNode.contentSizeInPoints.width / 2) * sNode.scaleXInPoints;
                        } if(abs((sNode.bottomInPoints + (sNode.contentSizeInPoints.height / 2) * sNode.scaleYInPoints) - (node.bottomInPoints + node.contentSizeInPoints.height / 2)) < sensitivity) {
                            sNode.bottomInPoints = node.bottomInPoints + node.contentSizeInPoints.height / 2 - (sNode.contentSizeInPoints.height / 2) * sNode.scaleYInPoints;
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
                            newY = sNode.position.y;
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
                
                /*
                 // Center View
                 if(abs((sNode.leftInPoints + (sNode.contentSizeInPoints.width / 2) * sNode.scaleXInPoints) - (sNode.parent.contentSizeInPoints.width / 2) ) < sensitivity) {
                 sNode.leftInPoints = (sNode.parent.contentSizeInPoints.width / 2) - (sNode.contentSizeInPoints.width / 2) * sNode.scaleXInPoints;
                 }
                 if(abs((sNode.bottomInPoints + (sNode.contentSizeInPoints.height / 2) * sNode.scaleYInPoints) - (sNode.parent.contentSizeInPoints.height / 2)) < sensitivity) {
                 sNode.bottomInPoints = (sNode.parent.contentSizeInPoints.height / 2) - (sNode.contentSizeInPoints.height / 2) * sNode.scaleYInPoints;
                 }
                 
                 // Snap to sides to edge of view
                 if(abs(sNode.leftInPoints) < sensitivity) {
                 sNode.leftInPoints = 0;
                 } else if(abs(sNode.rightInPoints - sNode.parent.contentSizeInPoints.width) < sensitivity) {
                 sNode.rightInPoints = sNode.parent.contentSizeInPoints.width;
                 }
                 if(abs(sNode.topInPoints - sNode.parent.contentSizeInPoints.height) < sensitivity) {
                 sNode.topInPoints = sNode.parent.contentSizeInPoints.height;
                 } else if(abs(sNode.bottomInPoints) < sensitivity) {
                 sNode.bottomInPoints = 0;
                 }
                 */
            
            
            nodesToSearchForSnapping = nil;
            cs = nil;
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
    
    
    [self findSnappedLines];
    [appDelegate refreshProperty:@"position"];
}

#pragma mark - Mouse Events

- (BOOL) mouseDown:(CGPoint)pt event:(NSEvent*)event
{
    if (!self.visible) return NO;
    
    if ([appDelegate.selectedNode hitTestWithWorldPos:pt]) {
        [self updateLines];
    }
    
    return YES;
}

- (BOOL) mouseDragged:(CGPoint)pt event:(NSEvent*)event
{
    
    if (!self.visible) return NO;

    [self snapIfNeeded];
    [self drawLines];
    
    return YES;
}

- (BOOL) mouseUp:(CGPoint)pt event:(NSEvent*)event
{
    if (!self.visible) return NO;
    
    return YES;
}

@end
