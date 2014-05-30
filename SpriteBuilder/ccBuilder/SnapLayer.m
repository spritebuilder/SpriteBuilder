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
            
            NSArray *nodesToSearchForSnapping = [self sortByDistance:sNode];
            
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
    
    for(Snap* snapCheck in snapLines) {
        if(snapCheck->position==snap->position) return;
    }
    [snapLines addObject:snap];
}

-(void) addHorizontalSnapLine:(float)y{
    Snap* snap = [[Snap alloc] init];
    snap->position    = roundf(y);
    snap->orientation = kCCBSnapOrientationHorizontal;
    snap->type        = kCCBSnapTypeDefault;
    
    for(Snap* snapCheck in snapLines) {
        if(snapCheck->position==snap->position) return;
    }
    [snapLines addObject:snap];
}

- (NSArray*) sortByDistance:(CCNode*)sNode {
    
    NSArray* nodesToSearchForSnapping = nil;
    nodesToSearchForSnapping = [sNode.parent.children sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        CCNode *nodeA = (CCNode*)a;
        CCNode *nodeB = (CCNode*)b;
        
        float distanceA = ccpDistance(sNode.positionInPoints,nodeA.positionInPoints);
        float distanceB = ccpDistance(sNode.positionInPoints,nodeB.positionInPoints);
        
        if(distanceA>distanceB) {
            return NSOrderedDescending;
        } else if (distanceA<distanceB){
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
        
    }];

    return nodesToSearchForSnapping;
}

- (void)snapIfNeeded {
    
    CocosScene* cs = [CocosScene cocosScene];
    
    for(CCNode *sNode in appDelegate.selectedNodes) {
        
        if(sNode && sNode.parent) {
            
            CGPoint currentLocationInPoints = sNode.positionInPoints;

            NSArray *nodesToSearchForSnapping = [self sortByDistance:sNode];

            BOOL snapX = YES;
            BOOL snapY = YES;

            for(CCNode *node in nodesToSearchForSnapping) {
                
                if(node != sNode) { // Ignore the selected node
                    
                    NSPoint sPoint = [sNode convertToWorldSpace:sNode.anchorPointInPoints];
                    NSPoint point  = [node convertToWorldSpace:node.anchorPointInPoints];
                    
                    // Snap from anchorPoint
                    if(snapX && abs(sPoint.x - point.x) < sensitivity) {
                        sPoint.x = point.x;
                        snapX = NO;
                    }
                    if(snapY && abs(sPoint.y - point.y) < sensitivity) {
                        sPoint.y = point.y;
                        snapY = NO;
                    }
                    
                    sNode.positionInPoints = [sNode.parent convertToNodeSpace:sPoint];
                    
                    // Snap from center
                    if(snapX && abs(sNode.centerXInPoints - node.centerXInPoints) < sensitivity) {
                        sNode.centerXInPoints = node.centerXInPoints;
                        snapX = NO;
                    }
					if(snapY && abs(sNode.centerYInPoints - node.centerYInPoints) < sensitivity) {
                        sNode.centerYInPoints = node.centerYInPoints;
                        snapY = NO;
                    }
                    
                    // Snap to opposite sides
                    if(snapX && abs(sNode.leftInPoints - node.rightInPoints) < sensitivity) {
                        sNode.leftInPoints = node.rightInPoints;
                        snapX = NO;
                    } else if(snapX && abs(sNode.rightInPoints - node.leftInPoints) < sensitivity) {
                        sNode.rightInPoints = node.leftInPoints;
                        snapX = NO;
                    }
                    
                    if(snapX && abs(sPoint.x - node.rightInPoints) < sensitivity) {
                        sPoint.x = node.rightInPoints;
                        sNode.positionInPoints = [sNode.parent convertToNodeSpace:sPoint];
                        snapX = NO;
                    } else if(snapX && abs(sPoint.x - node.leftInPoints) < sensitivity) {
                        sPoint.x = node.leftInPoints;
                        sNode.positionInPoints = [sNode.parent convertToNodeSpace:sPoint];
                        snapX = NO;
                    }
                    
                    if(snapY && abs(sNode.topInPoints - node.bottomInPoints) < sensitivity) {
                        sNode.topInPoints = node.bottomInPoints;
                        snapY = NO;
                    } else if(snapY && abs(sNode.bottomInPoints - node.topInPoints) < sensitivity) {
                        sNode.bottomInPoints = node.topInPoints;
                        snapY = NO;
                    }
                    
                    if(snapY && abs(sPoint.y - node.bottomInPoints) < sensitivity) {
                        sPoint.y = node.bottomInPoints;
                        sNode.positionInPoints = [sNode.parent convertToNodeSpace:sPoint];
                        snapY = NO;
                    } else if(snapY && abs(sPoint.y - node.topInPoints) < sensitivity) {
                        sPoint.y = node.topInPoints;
                        sNode.positionInPoints = [sNode.parent convertToNodeSpace:sPoint];
                        snapY = NO;
                    }
                    
                    // Snap to same sides
                    if(snapX && abs(sNode.leftInPoints - node.leftInPoints) < sensitivity) {
                        sNode.leftInPoints = node.leftInPoints;
                        snapX = NO;
                    } else if(snapX && abs(sNode.rightInPoints - node.rightInPoints) < sensitivity) {
                        sNode.rightInPoints = node.rightInPoints;
                        snapX = NO;
                    }
                    
                    if(snapY && abs(sNode.topInPoints - node.topInPoints) < sensitivity) {
                        sNode.topInPoints    = node.topInPoints;
                        snapY = NO;
                    } else if(snapY && abs(sNode.bottomInPoints - node.bottomInPoints) < sensitivity) {
                        sNode.bottomInPoints = node.bottomInPoints;
                        snapY = NO;
                    }
                    
                }
                
                
            }
            
            
            CCNode* edgeNode = sNode.parent;
            if(CGSizeEqualToSize(sNode.parent.contentSizeInPoints,CGSizeZero)) {
                edgeNode = cs.rootNode;
            }
            
            // Anchor
            NSPoint sPoint = [sNode convertToWorldSpace:sNode.anchorPointInPoints];

            // Edge Snap
            if(abs(sNode.leftInPoints - edgeNode.leftInPoints) < sensitivity) {
                sNode.leftInPoints = edgeNode.leftInPoints;
            } else if(abs(sNode.rightInPoints - edgeNode.rightInPoints) < sensitivity) {
                sNode.rightInPoints = edgeNode.rightInPoints;
            }
            
            if(abs(sPoint.x - edgeNode.leftInPoints) < sensitivity) {
                sPoint.x = edgeNode.leftInPoints;
                 sNode.positionInPoints = [sNode.parent convertToNodeSpace:sPoint];
            } else if(abs(sPoint.x - edgeNode.rightInPoints) < sensitivity) {
                sPoint.x = edgeNode.rightInPoints;
                 sNode.positionInPoints = [sNode.parent convertToNodeSpace:sPoint];
            }
            
            if(abs(sNode.topInPoints - edgeNode.topInPoints) < sensitivity) {
                sNode.topInPoints = edgeNode.topInPoints;
            } else if(abs(sNode.bottomInPoints - edgeNode.bottomInPoints) < sensitivity) {
                sNode.bottomInPoints = edgeNode.bottomInPoints;
            }
            
            if(abs(sPoint.y - edgeNode.topInPoints) < sensitivity) {
                sPoint.y = edgeNode.topInPoints;
                 sNode.positionInPoints = [sNode.parent convertToNodeSpace:sPoint];
            } else if(abs(sPoint.y - edgeNode.bottomInPoints) < sensitivity) {
                sPoint.y = edgeNode.bottomInPoints;
                 sNode.positionInPoints = [sNode.parent convertToNodeSpace:sPoint];
            }
            
            nodesToSearchForSnapping = nil;
            CGPoint difference = ccpSub(currentLocationInPoints, sNode.positionInPoints);
            for(CCNode *node in appDelegate.selectedNodes) {
                if(node != sNode) {
                    NSPoint point = ccpSub(node.positionInPoints, difference);
                    sNode.positionInPoints = [sNode.parent convertToNodeSpace:point];
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
