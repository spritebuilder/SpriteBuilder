//
//  PhysicsHandler.m
//  SpriteBuilder
//
//  Created by Viktor on 9/30/13.
//
//

#import "PhysicsHandler.h"
#import "AppDelegate.h"
#import "CCNode+NodeInfo.h"
#import "NodePhysicsBody.h"
#import "chipmunk.h"
#import "CocosScene.h"

#define kCCBPhysicsHandleRadius 5
#define kCCBPhysicsLineSegmFuzz 5
#define kCCBPhysicsSnapDist 10

float distanceFromLineSegment(CGPoint a, CGPoint b, CGPoint c)
{
    float ax = a.x;
    float ay = a.y;
    float bx = b.x;
    float by = b.y;
    float cx = c.x;
    float cy = c.y;
    
	float r_numerator = (cx-ax)*(bx-ax) + (cy-ay)*(by-ay);
	float r_denomenator = (bx-ax)*(bx-ax) + (by-ay)*(by-ay);
	float r = r_numerator / r_denomenator;
    
    float px = ax + r*(bx-ax);
    float py = ay + r*(by-ay);
    
    float s =  ((ay-cy)*(bx-ax)-(ax-cx)*(by-ay) ) / r_denomenator;
    
    float distanceSegment = 0;
	float distanceLine = fabs(s)*sqrt(r_denomenator);
    
	float xx = px;
	float yy = py;
    
	if ( (r >= 0) && (r <= 1) )
	{
		distanceSegment = distanceLine;
	}
	else
	{
        
		float dist1 = (cx-ax)*(cx-ax) + (cy-ay)*(cy-ay);
		float dist2 = (cx-bx)*(cx-bx) + (cy-by)*(cy-by);
		if (dist1 < dist2)
		{
			xx = ax;
			yy = ay;
			distanceSegment = sqrtf(dist1);
		}
		else
		{
			xx = bx;
			yy = by;
			distanceSegment = sqrtf(dist2);
		}
	}
    
	return distanceSegment;
}

@implementation PhysicsHandler

- (void) awakeFromNib
{
    _mouseDownInHandle = -1;
}

- (void) willChangeSelection
{
    [self willChangeValueForKey:@"selectedNodePhysicsEnabled"];
}

- (void) didChangeSelection
{
    // Update properties
    [self didChangeValueForKey:@"selectedNodePhysicsEnabled"];
}

- (void) setSelectedNodePhysicsEnabled:(BOOL)enabled
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*physicsBody"];
    
    if (enabled)
    {
        [AppDelegate appDelegate].selectedNode.nodePhysicsBody = [[[NodePhysicsBody alloc] initWithNode:[AppDelegate appDelegate].selectedNode] autorelease];
    }
    else
    {
        [AppDelegate appDelegate].selectedNode.nodePhysicsBody = NULL;
    }
    
    // Update physics body
    self.selectedNodePhysicsBody = [AppDelegate appDelegate].selectedNode.nodePhysicsBody;
}

- (BOOL) selectedNodePhysicsEnabled
{
    if ([AppDelegate appDelegate].selectedNode.nodePhysicsBody) return YES;
    else return NO;
}

- (BOOL) editingPhysicsBody
{
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    NSUInteger tabIdx = [[AppDelegate appDelegate].itemTabView indexOfTabViewItem:[AppDelegate appDelegate].itemTabView.selectedTabViewItem];
    
    return (node && node.nodePhysicsBody && tabIdx == 2);
}

- (int) handleIndexForPos:(CGPoint) pos
{
    CGPoint anchorPointPos = [self selectedAnchorInWorld];
    float scale = [self scaleFactor];
    
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    
    int idx = 0;
    for (NSValue* ptVal in body.points)
    {
        CGPoint pt = ccpAdd(anchorPointPos, ccpMult([ptVal pointValue], scale));
        
        float distance = ccpDistance(pt, pos);
        
        if (distance <= kCCBPhysicsHandleRadius)
        {
            return idx;
        }
        idx ++;
    }
    
    return -1;
}

- (BOOL) point:(CGPoint)pt onLineFrom:(CGPoint)start to:(CGPoint) end
{
    CGPoint left;
    CGPoint right;
    
    if (start.x <= end.x)
    {
        left = start;
        right = end;
    }
    else
    {
        left = end;
        right = start;
    }
    
    if (pt.x + kCCBPhysicsLineSegmFuzz < left.x || right.x < pt.x - kCCBPhysicsLineSegmFuzz) return NO;
    if (pt.y + kCCBPhysicsLineSegmFuzz < min(left.y, right.y) || max(left.y, right.y) < pt.y - kCCBPhysicsLineSegmFuzz) return NO;
    
    float dX = right.x - left.x;
    float dY = right.y - left.y;
    
    if (fabsf(dX) < kCCBPhysicsLineSegmFuzz || fabsf(dY) < kCCBPhysicsLineSegmFuzz) return YES;
    
    float slope = dY / dX;
    float offset = left.y - left.x * slope;
    float calcY = pt.x * slope + offset;
    
    return (pt.y - kCCBPhysicsLineSegmFuzz <= calcY && calcY <= pt.y + kCCBPhysicsLineSegmFuzz);
}

- (int) lineSegmIndexForPos:(CGPoint) pos
{
    CGPoint anchorPointPos = [self selectedAnchorInWorld];
    float scale = [self scaleFactor];
    
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    
    for (int idx = 0; idx < body.points.count; idx++)
    {
        NSValue* ptVal0 = [body.points objectAtIndex:idx];
        NSValue* ptVal1 = [body.points objectAtIndex:(idx + 1) % body.points.count];
        
        CGPoint pt0 = ccpAdd(anchorPointPos, ccpMult([ptVal0 pointValue], scale));
        CGPoint pt1 = ccpAdd(anchorPointPos, ccpMult([ptVal1 pointValue], scale));
        
        float distance = distanceFromLineSegment(pt0, pt1, pos);
        
        if (distance <= kCCBPhysicsLineSegmFuzz)
        {
            return idx;
        }
    }
    return -1;
}

- (void) makeConvexHull
{
    NSArray* pts = self.selectedNodePhysicsBody.points;
    int numPts = pts.count;
    
    cpVect* verts = malloc(sizeof(cpVect) * numPts);
    int idx = 0;
    for (NSValue* ptVal in pts)
    {
        CGPoint pt = [ptVal pointValue];
        verts[idx].x = pt.x;
        verts[idx].y = pt.y;
        idx++;
    }
    
    int newNumPts = cpConvexHull(numPts, verts, NULL, NULL, 0.0f);
    
    NSMutableArray* hull = [NSMutableArray array];
    for (idx = 0; idx < newNumPts; idx++)
    {
        [hull addObject:[NSValue valueWithPoint:ccp(verts[idx].x, verts[idx].y)]];
    }
    
    self.selectedNodePhysicsBody.points = hull;
}

- (CGPoint) snapPoint:(CGPoint)src toPt0:(CGPoint)pt0 andPt1:(CGPoint)pt1
{
    CGPoint snapped = src;
    
    // Snap x value
    float xDist0 = fabsf(src.x - pt0.x);
    float xDist1 = fabsf(src.x - pt1.x);
    
    if (min(xDist0, xDist1) < kCCBPhysicsSnapDist)
    {
        if (xDist0 < xDist1) snapped.x = pt0.x;
        else snapped.x = pt1.x;
    }
    
    // Snap y value
    float yDist0 = fabsf(src.y - pt0.y);
    float yDist1 = fabsf(src.y - pt1.y);
    
    if (min(yDist0, yDist1) < kCCBPhysicsSnapDist)
    {
        if (yDist0 < yDist1) snapped.y = pt0.y;
        else snapped.y = pt1.y;
    }
    
    return snapped;
}

- (BOOL) mouseDown:(CGPoint)pos event:(NSEvent*)event
{
    if (!self.editingPhysicsBody) return NO;
    
    float scale = [self scaleFactor];
    
    int handleIdx = [self handleIndexForPos:pos];
    int lineIdx = [self lineSegmIndexForPos:pos];
    
    _mouseDownPos = pos;
    _mouseDownInHandle = handleIdx;
    
    if (handleIdx != -1)
    {
        _handleStartPos = [[self.selectedNodePhysicsBody.points objectAtIndex:handleIdx] pointValue];
        
        return YES;
    }
    else if (lineIdx != -1)
    {
        // Add new segment
        CGPoint localPos = ccpMult(ccpSub(pos, [self selectedAnchorInWorld]), 1.0f/scale);
        
        NSMutableArray* points = [self.selectedNodePhysicsBody.points mutableCopy];
        [points insertObject:[NSValue valueWithPoint:localPos] atIndex:lineIdx + 1];
        self.selectedNodePhysicsBody.points = points;
        
        // Set this segment as edited
        _handleStartPos = localPos;
        _mouseDownInHandle = lineIdx + 1;
        
        return YES;
    }
    else
    {
        // Clicked outside handle, pass event down to selections
        return NO;
    }
}

- (BOOL) mouseDragged:(CGPoint)pos event:(NSEvent*)event
{
    if (!self.editingPhysicsBody) return NO;
    
    float scale = [self scaleFactor];
    
    if (_mouseDownInHandle != -1)
    {
        CGPoint delta = ccpSub(pos, _mouseDownPos);
        delta = ccpMult(delta, 1.0f/scale);
        CGPoint newPos = ccpAdd(_handleStartPos, delta);
        
        NSMutableArray* points = [self.selectedNodePhysicsBody.points mutableCopy];
        
        if ([event modifierFlags] & NSShiftKeyMask)
        {
            // Handle snapping if shift is down
            CGPoint pt0 = [[points objectAtIndex:(_mouseDownInHandle + points.count - 1) % points.count] pointValue];
            CGPoint pt1 = [[points objectAtIndex:(_mouseDownInHandle + 1) % points.count] pointValue];
            
            newPos = [self snapPoint:newPos toPt0:pt0 andPt1:pt1];
        }
        
        [points replaceObjectAtIndex:_mouseDownInHandle withObject:[NSValue valueWithPoint:newPos]];
        self.selectedNodePhysicsBody.points = points;
        
        return YES;
    }
    else
    {
        // Not doing any physics editing
        return NO;
    }
}

- (BOOL) mouseUp:(CGPoint)pos event:(NSEvent*)event
{
    if (_mouseDownInHandle != -1)
    {
        [self makeConvexHull];
        
        return YES;
    }
    
    return NO;
}

- (CGPoint) selectedAnchorInWorld
{
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    // Find the anchor point
    CGPoint localAnchor = ccp(node.anchorPoint.x * node.contentSizeInPoints.width,
                              node.anchorPoint.y * node.contentSizeInPoints.height);
    
    CGPoint anchorPointPos = [node convertToWorldSpace:localAnchor];
    
    return anchorPointPos;
}

- (void) updatePhysicsEditor:(CCNode*) editorView
{
    float scale = [self scaleFactor];
    
    if (self.editingPhysicsBody)
    {
        CCNode* node = [AppDelegate appDelegate].selectedNode;
        CGPoint anchorPointPos = [self selectedAnchorInWorld];
        
        // Position physic corners
        NodePhysicsBody* body = node.nodePhysicsBody;
        
        CGPoint* points = malloc(sizeof(CGPoint)*body.points.count);
        
        int i = 0;
        for (NSValue* ptVal in body.points)
        {
            // Absolute handle position
            CGPoint pt = ccpAdd(anchorPointPos, ccpMult([ptVal pointValue], scale));
            points[i] = pt;
            
            CCSprite* handle = [CCSprite spriteWithFile:@"select-physics-corner.png"];
            handle.position = pt;
            [editorView addChild:handle];
            i++;
        }
        
        CCDrawNode* drawing = [CCDrawNode node];
        [drawing drawPolyWithVerts:points count:body.points.count fillColor:ccc4f(0, 0, 0, 0) borderWidth:1 borderColor:ccc4f(1, 1, 1, 0.3)];
        
        [editorView addChild:drawing z:-1];
        
        free(points);
    }
}

- (float) scaleFactor
{
    return [[CocosScene cocosScene] stageZoom];
}
@end
