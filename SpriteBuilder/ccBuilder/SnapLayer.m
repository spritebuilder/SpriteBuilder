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

#define kOptionKey 58

@interface SnapLayer() {
    BOOL optionKeyDown;
    float sensitivity;
}

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) CCDrawNode *drawLayer;
@property (nonatomic, strong) NSMutableSet *verticalSnapLines;
@property (nonatomic, strong) NSMutableSet *horizontalSnapLines;

@end

@implementation SnapLayer

@synthesize appDelegate;
@synthesize drawLayer;
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
    sensitivity = 4;
    drawLayer = [CCDrawNode node];
    verticalSnapLines = [NSMutableSet new];
    horizontalSnapLines = [NSMutableSet new];
    [self addChild:drawLayer];
    [self setupOptionKeyListener];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLines) name:SnapLayerRefreshLines object:nil];
}

- (void)setupOptionKeyListener {
    [NSEvent addLocalMonitorForEventsMatchingMask:NSFlagsChangedMask handler:^NSEvent *(NSEvent *incomingEvent) {
        if(incomingEvent.keyCode == kOptionKey) {
            if(incomingEvent.modifierFlags & NSAlternateKeyMask) {
                optionKeyDown = YES;
            } else {
                optionKeyDown = NO;
            }
        }
        return incomingEvent;
    }];
}

#pragma mark - Memory Management

- (void)dealloc {
    [NSEvent removeMonitor:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Drawing

- (void)drawLines {
    [drawLayer clear];
    
    CocosScene *cs = [CocosScene cocosScene];
    for(CCNode *sNode in appDelegate.selectedNodes) {
        
        if(sNode != cs.rootNode) {
            for(NSNumber *x in verticalSnapLines) {
                CGPoint start = [self getStagePointWithPoint:ccp([x floatValue], 0) forNode:sNode]; // Get the start coordinate in relation to the stage
                int screenX = start.x; // Remember the x position so we can determine wether or not to draw the line if it's outside of the stage
                start.y = 0; // Make sure to line draws to the bottom side of the stage node
                start = [cs convertToViewSpace:start]; // Convert the stage coordinate to the screen coordinate
                CGPoint end = [self getStagePointWithPoint:ccp([x floatValue], cs.stageSize.height) forNode:sNode]; // Get the end coordinate in relation to the stage
                end.y = cs.stageSize.height; // Make sure to line draws to the top side of the stage node
                end = [cs convertToViewSpace:end]; // Convert the stage coordinate to the screen coordinate
                if(screenX >= 0 && screenX <= cs.stageSize.width) { // Don't draw lines outside of the stage node
                    [drawLayer drawSegmentFrom:start to:end radius:1 color:[CCColor whiteColor]];
                }
            }
            for(NSNumber *y in horizontalSnapLines) {
                CGPoint start = [self getStagePointWithPoint:ccp(0, [y floatValue]) forNode:sNode]; // Get the start coordinate in relation to the stage
                int screenY = start.y; // Remember the y position so we can determine wether or not to draw the line if it's outside of the stage
                start.x = 0; // Make sure to line draws to the left side of the stage node
                start = [cs convertToViewSpace:start]; // Convert the stage coordinate to the screen coordinate
                CGPoint end = [self getStagePointWithPoint:ccp(cs.stageSize.width, [y floatValue]) forNode:sNode]; // Get the end coordinate in relation to the stage
                end.x = cs.stageSize.width; // Make sure to line draws to the right side of the stage node
                end = [cs convertToViewSpace:end]; // Convert the stage coordinate to the screen coordinate
                if(screenY >= 0 && screenY <= cs.stageSize.height) { // Don't draw lines outside of the stage node
                    [drawLayer drawSegmentFrom:start to:end radius:1 color:[CCColor whiteColor]];
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
            NSMutableArray *nodesToSearchForSnapping = [NSMutableArray arrayWithArray:sNode.parent.children]; // Try and snap with all children of the selected node's parent
            for(CCNode *node in nodesToSearchForSnapping) {
                if(node != sNode) { // Ignore the selected node
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
            
            cs = nil;
            nodesToSearchForSnapping = nil;
        }
    }
}

#pragma mark - Snapping Methods

- (void)snapIfNeeded {
    if(!optionKeyDown) { // Don't snap if the user is holding down the option key
        for(CCNode *sNode in appDelegate.selectedNodes) {
            if(sNode && sNode.parent) {
                CGPoint currentLocationInPoints = sNode.positionInPoints;
                CocosScene* cs = [CocosScene cocosScene];
                NSMutableArray *nodesToSearchForSnapping = [NSMutableArray arrayWithArray:sNode.parent.children]; // Try and snap with all children of the selected node's parent
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
    }
    [self findSnappedLines];
    [appDelegate refreshProperty:@"position"];
}

#pragma mark - Mouse Events

- (BOOL) mouseDown:(CGPoint)pt event:(NSEvent*)event
{
    BOOL success = YES;
    
    if ([appDelegate.selectedNode hitTestWithWorldPos:pt]) {
        [self updateLines];
    } else {
        [drawLayer clear];
    }
    
    return success;
}

- (BOOL) mouseDragged:(CGPoint)pt event:(NSEvent*)event
{
    BOOL success = YES;
    
    [self snapIfNeeded];
    [self drawLines];
    
    return success;
}

- (BOOL) mouseUp:(CGPoint)pt event:(NSEvent*)event
{
    BOOL success = YES;
    
    if ([appDelegate.selectedNode hitTestWithWorldPos:pt]) {
        [self updateLines];
    } else {
        [drawLayer clear];
    }
    
    return success;
}

@end
