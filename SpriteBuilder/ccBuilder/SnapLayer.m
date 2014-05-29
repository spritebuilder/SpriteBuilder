//
//  SnapLayer.m
//  SpriteBuilder
//
//  Created by Michael Daniels on 4/8/14.
//  Extended by SpriteBuilder Authors May 2014
//
//

#import "SnapLayer.h"
#import "AppDelegate.h"
#import "CocosScene.h"
#import "CCNode+PositionExtentions.h"
#import "PositionPropertySetter.h"
#import "NotificationNames.h"

#define kSnapLayerSensitivity       4
#define kSnapLayerSensitivityLine   1

#pragma mark Guide
@interface Snap : NSObject {
@public
    float position;
    int orientation;
    int type;
    float length;
}
@end

@implementation Snap

@end

@interface SnapLayer() {
    float sensitivity;
    float gridSize;
    CGPoint lastPoint;
    BOOL drag;
}

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSMutableSet *snapLines;

@end

@implementation SnapLayer

@synthesize appDelegate;

@synthesize snapLines;

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

    snapLines   = [NSMutableSet new];

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
            
            for(Snap *s in snapLines) {
                
                if(s->orientation==kCCBSnapOrientationHorizontal) {
                    
                    CGPoint viewPos = ccp(0, s->position);
                    
                    if (CGRectContainsPoint(viewRect, viewPos))
                    {
                        CCSprite9Slice* sprtGuide = [CCSprite9Slice spriteWithImageNamed:@"ruler-guide.png"];
                        sprtGuide.contentSizeType = CCSizeTypeMake(CCSizeUnitPoints, CCSizeUnitUIPoints);
                        sprtGuide.contentSize = CGSizeMake(winSize.width, 2);
                        sprtGuide.anchorPoint = ccp(0, 0.5f);
                        sprtGuide.position = ccp(roundf(viewPos.x),roundf(viewPos.y));
                        [sprtGuide setColor:[CCColor colorWithRed:0.84 green:0.27 blue:0.78 alpha:0.7]];
                        [self addChild:sprtGuide];
                        
                    }
                    
                }
            
                if(s->orientation==kCCBSnapOrientationVertical) {
                    CGPoint viewPos = ccp(s->position, 0);
                    
                    if (CGRectContainsPoint(viewRect, viewPos))
                    {
                        CCSprite9Slice* sprtGuide = [CCSprite9Slice spriteWithImageNamed:@"ruler-guide.png"];
                        sprtGuide.contentSizeType = CCSizeTypeMake(CCSizeUnitPoints, CCSizeUnitUIPoints);
                        sprtGuide.contentSize = CGSizeMake(winSize.height, 2);
                        sprtGuide.anchorPoint = ccp(0, 0.5f);
                        sprtGuide.rotation = -90;
                        sprtGuide.position = ccp(roundf(viewPos.x),roundf(viewPos.y));
                        [sprtGuide setColor:[CCColor colorWithRed:0.84 green:0.27 blue:0.78 alpha:0.7]];
                        [self addChild:sprtGuide];
                        
                    }
                    
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
    
    [snapLines removeAllObjects];
    
    CocosScene* cs = [CocosScene cocosScene];
    
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
                    if(abs(sPoint.x - point.x) < kSnapLayerSensitivityLine) {
                        [self addVerticalSnapLine:sPoint.x];
                    }
                    if(abs(sPoint.y - point.y) < kSnapLayerSensitivityLine) {
                        [self addHorizontalSnapLine:sPoint.y];
                    }
                    
                    // Snap lines from center
                    if(abs(sNode.centerXInPoints - node.centerXInPoints) < kSnapLayerSensitivityLine) {
                        [self addVerticalSnapLine:sNode.centerXInPoints];
                    }
					if(abs(sNode.centerYInPoints - node.centerYInPoints) < kSnapLayerSensitivityLine) {
                        [self addHorizontalSnapLine:sNode.centerYInPoints];
                    }
                    
                    // Snap lines for opposite sides
                    if(abs(sNode.leftInPoints - node.rightInPoints) < kSnapLayerSensitivityLine) {
                        [self addVerticalSnapLine:sNode.leftInPoints];
                    }
                    if(abs(sNode.rightInPoints - node.leftInPoints) < kSnapLayerSensitivityLine) {
                        [self addVerticalSnapLine:sNode.rightInPoints];
                        
                    }
                    
                    if(abs(sPoint.x - node.rightInPoints) < kSnapLayerSensitivityLine) {
                        [self addVerticalSnapLine:node.rightInPoints];
                    }
                    
                    if(abs(sPoint.x - node.leftInPoints) < kSnapLayerSensitivityLine) {
                        [self addVerticalSnapLine:node.leftInPoints];
                    }
                    
                    if(abs(sNode.topInPoints - node.bottomInPoints) < kSnapLayerSensitivityLine) {
                        [self addHorizontalSnapLine:sNode.topInPoints];
                    }
                    if(abs(sNode.bottomInPoints - node.topInPoints) < kSnapLayerSensitivityLine) {
                        [self addHorizontalSnapLine:sNode.bottomInPoints];
                    }
                    
                    if(abs(sPoint.y - node.bottomInPoints) < kSnapLayerSensitivityLine) {
                        [self addHorizontalSnapLine:node.bottomInPoints];
                    }
                    
                    if(abs(sPoint.y - node.topInPoints) < kSnapLayerSensitivityLine) {
                        [self addHorizontalSnapLine:node.topInPoints];
                    }
                    
                    // Snap lines for same sides
                    if(abs(sNode.leftInPoints - node.leftInPoints) < kSnapLayerSensitivityLine) {
                        [self addVerticalSnapLine:sNode.leftInPoints];
                    }
                    if(abs(sNode.rightInPoints - node.rightInPoints) < kSnapLayerSensitivityLine) {
                        [self addVerticalSnapLine:sNode.rightInPoints];
                    }
                    if(abs(sNode.topInPoints - node.topInPoints) < kSnapLayerSensitivityLine) {
                        [self addHorizontalSnapLine:sNode.topInPoints];
                    }
                    if(abs(sNode.bottomInPoints - node.bottomInPoints) < kSnapLayerSensitivityLine) {
                        [self addHorizontalSnapLine:sNode.bottomInPoints];
                    }
                }
            }
            
            CCNode* edgeNode = sNode.parent;
            if(CGSizeEqualToSize(sNode.parent.contentSizeInPoints,CGSizeZero)) {
                edgeNode = cs.rootNode;
            }
            
            // Anchor
            NSPoint sPoint = [sNode convertToWorldSpace:sNode.anchorPointInPoints];
            
            /*
            // Center Snap
            if(abs(sNode.centerXInPoints - edgeNode.centerXInPoints ) < kSnapLayerSensitivityLine) {
                [self addVerticalSnapLine:edgeNode.centerXInPoints];
            }
            if(abs(sNode.centerYInPoints - edgeNode.centerYInPoints) < kSnapLayerSensitivityLine) {
                [self addHorizontalSnapLine:edgeNode.centerYInPoints];
            }
            */
            
            // Edge Snap
            if(abs(sNode.leftInPoints - edgeNode.leftInPoints) < kSnapLayerSensitivityLine) {
                [self addVerticalSnapLine:edgeNode.leftInPoints];
            }
            if(abs(sNode.rightInPoints - edgeNode.rightInPoints) < kSnapLayerSensitivityLine) {
                [self addVerticalSnapLine:edgeNode.rightInPoints];
            }
            
            if(abs(sPoint.x - edgeNode.leftInPoints) < kSnapLayerSensitivityLine) {
                [self addVerticalSnapLine:edgeNode.leftInPoints];
            }
            if(abs(sPoint.x - edgeNode.rightInPoints) < kSnapLayerSensitivityLine) {
                [self addVerticalSnapLine:edgeNode.rightInPoints];
            }
            
            if(abs(sNode.topInPoints - edgeNode.topInPoints) < kSnapLayerSensitivityLine) {
                [self addHorizontalSnapLine:edgeNode.topInPoints];
            }
            if(abs(sNode.bottomInPoints - edgeNode.bottomInPoints) < kSnapLayerSensitivityLine) {
                [self addHorizontalSnapLine:edgeNode.bottomInPoints];
            }
            
            if(abs(sPoint.y - edgeNode.topInPoints) < kSnapLayerSensitivityLine) {
                [self addHorizontalSnapLine:edgeNode.topInPoints];
            }
            if(abs(sPoint.y - edgeNode.bottomInPoints) < kSnapLayerSensitivityLine) {
                [self addHorizontalSnapLine:edgeNode.bottomInPoints];
            }
						
            nodesToSearchForSnapping = nil;
        }
    }
}

-(void) addVerticalSnapLine:(float)x {
    Snap* snap = [[Snap alloc] init];
    snap->position    = roundf(x);
    snap->orientation = kCCBSnapOrientationVertical;
    snap->type        = kCCBSnapTypeDefault;
    [snapLines addObject:snap];
}

-(void) addHorizontalSnapLine:(float)y{
    Snap* snap = [[Snap alloc] init];
    snap->position    = roundf(y);
    snap->orientation = kCCBSnapOrientationHorizontal;
    snap->type        = kCCBSnapTypeDefault;
    [snapLines addObject:snap];
}

#pragma mark - Snapping Methods

- (void)snapIfNeeded {
    
    CocosScene* cs = [CocosScene cocosScene];
    
    for(CCNode *sNode in appDelegate.selectedNodes) {
        
        if(sNode && sNode.parent) {
            
            CGPoint currentLocationInPoints = sNode.positionInPoints;
            
            // Try and snap with all children of the selected node's parent
            NSMutableArray *nodesToSearchForSnapping = [NSMutableArray arrayWithArray:sNode.parent.children];
            
            for(CCNode *node in nodesToSearchForSnapping) {
                
                if(node != sNode) { // Ignore the selected node
                    NSPoint sPoint = [sNode convertToWorldSpace:sNode.anchorPointInPoints];
                    NSPoint point  = [node convertToWorldSpace:node.anchorPointInPoints];
                    
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
                    
                    if(abs(sPoint.x - node.rightInPoints) < sensitivity) {
                        sPoint.x = node.rightInPoints;
                        sNode.position = [sNode convertPositionFromPoints:[sNode.parent convertToNodeSpace:sPoint] type:self.positionType];
                    } else if(abs(sPoint.x - node.leftInPoints) < sensitivity) {
                        sPoint.x = node.leftInPoints;
                        sNode.position = [sNode convertPositionFromPoints:[sNode.parent convertToNodeSpace:sPoint] type:self.positionType];
                    }
                    
                    if(abs(sNode.topInPoints - node.bottomInPoints) < sensitivity) {
                        sNode.topInPoints = node.bottomInPoints;
                    } else if(abs(sNode.bottomInPoints - node.topInPoints) < sensitivity) {
                        sNode.bottomInPoints = node.topInPoints;
                    }
                    
                    if(abs(sPoint.y - node.bottomInPoints) < sensitivity) {
                        sPoint.y = node.bottomInPoints;
                        sNode.position = [sNode convertPositionFromPoints:[sNode.parent convertToNodeSpace:sPoint] type:self.positionType];
                    } else if(abs(sPoint.y - node.topInPoints) < sensitivity) {
                        sPoint.y = node.topInPoints;
                        sNode.position = [sNode convertPositionFromPoints:[sNode.parent convertToNodeSpace:sPoint] type:self.positionType];
                    }
                    
                    // Snap to same sides
                    if(abs(sNode.leftInPoints - node.leftInPoints) < sensitivity) {
                        sNode.leftInPoints = node.leftInPoints;
                    } else if(abs(sNode.rightInPoints - node.rightInPoints) < sensitivity) {
                        sNode.rightInPoints = node.rightInPoints;
                    }
                    if(abs(sNode.topInPoints - node.topInPoints) < sensitivity) {
                        sNode.topInPoints    = node.topInPoints;
                    } else if(abs(sNode.bottomInPoints - node.bottomInPoints) < sensitivity) {
                        sNode.bottomInPoints = node.bottomInPoints;
                    }
                    
                }
            }
            
            
            CCNode* edgeNode = sNode.parent;
            if(CGSizeEqualToSize(sNode.parent.contentSizeInPoints,CGSizeZero)) {
                edgeNode = cs.rootNode;
            }
            
            // Anchor
            NSPoint sPoint = [sNode convertToWorldSpace:sNode.anchorPointInPoints];
            
            /*
            // Container Center Snap (Not sure if we should keep it)
            if(abs(sNode.centerXInPoints - edgeNode.centerXInPoints ) < sensitivity) {
                sNode.centerXInPoints = edgeNode.centerXInPoints;
            }
            if(abs(sNode.centerYInPoints - edgeNode.centerYInPoints) < sensitivity) {
                sNode.centerYInPoints = edgeNode.centerYInPoints;
            }
            */

            // Edge Snap
            if(abs(sNode.leftInPoints - edgeNode.leftInPoints) < sensitivity) {
                sNode.leftInPoints = edgeNode.leftInPoints;
            } else if(abs(sNode.rightInPoints - edgeNode.rightInPoints) < sensitivity) {
                sNode.rightInPoints = edgeNode.rightInPoints;
            }
            
            if(abs(sPoint.x - edgeNode.leftInPoints) < sensitivity) {
                sPoint.x = edgeNode.leftInPoints;
                sNode.position = [sNode convertPositionFromPoints:[sNode.parent convertToNodeSpace:sPoint] type:self.positionType];
            } else if(abs(sPoint.x - edgeNode.rightInPoints) < sensitivity) {
                sPoint.x = edgeNode.rightInPoints;
                sNode.position = [sNode convertPositionFromPoints:[sNode.parent convertToNodeSpace:sPoint] type:self.positionType];
            }
            
            if(abs(sNode.topInPoints - edgeNode.topInPoints) < sensitivity) {
                sNode.topInPoints = edgeNode.topInPoints;
            } else if(abs(sNode.bottomInPoints - edgeNode.bottomInPoints) < sensitivity) {
                sNode.bottomInPoints = edgeNode.bottomInPoints;
            }
            
            if(abs(sPoint.y - edgeNode.topInPoints) < sensitivity) {
                sPoint.y = edgeNode.topInPoints;
                sNode.position = [sNode convertPositionFromPoints:[sNode.parent convertToNodeSpace:sPoint] type:self.positionType];
            } else if(abs(sPoint.y - edgeNode.bottomInPoints) < sensitivity) {
                sPoint.y = edgeNode.bottomInPoints;
                sNode.position = [sNode convertPositionFromPoints:[sNode.parent convertToNodeSpace:sPoint] type:self.positionType];
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
