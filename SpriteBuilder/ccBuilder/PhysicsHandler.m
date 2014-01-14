/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2013 Apportable Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "PhysicsHandler.h"
#import "AppDelegate.h"
#import "CCNode+NodeInfo.h"
#import "NodePhysicsBody.h"
#import "chipmunk.h"
#import "CocosScene.h"
#import "CCBUtil.h"
#import "CCSprite_Private.h"

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
    
    float s = ((ay-cy)*(bx-ax)-(ax-cx)*(by-ay)) / r_denomenator;
    
    float distanceSegment = 0;
	float distanceLine = fabs(s)*sqrt(r_denomenator);
    
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
			distanceSegment = sqrtf(dist1);
		}
		else
		{
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
        [AppDelegate appDelegate].selectedNode.nodePhysicsBody = [[NodePhysicsBody alloc] initWithNode:[AppDelegate appDelegate].selectedNode];
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
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    if (body.bodyShape == kCCBPhysicsBodyShapePolygon)
    {
        int idx = 0;
        for (NSValue* ptVal in body.points)
        {
            CGPoint pt = [node convertToWorldSpace:[ptVal pointValue]];
            
            float distance = ccpDistance(pt, pos);
            
            if (distance <= kCCBPhysicsHandleRadius)
            {
                return idx;
            }
            idx ++;
        }
    }
    else if (body.bodyShape == kCCBPhysicsBodyShapeCircle)
    {
        CGPoint center = [[body.points objectAtIndex:0] pointValue];
        center = [node convertToWorldSpace:center];
        
        CGPoint edge = ccpAdd(center, ccp(body.cornerRadius * [self radiusScaleFactor], 0));
        
        
        if (ccpDistance(center, pos) < kCCBPhysicsHandleRadius) return 0;
        else if (ccpDistance(edge, pos) < kCCBPhysicsHandleRadius) return 1;
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
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    if (body.bodyShape == kCCBPhysicsBodyShapePolygon)
    {
        for (int idx = 0; idx < body.points.count; idx++)
        {
            NSValue* ptVal0 = [body.points objectAtIndex:idx];
            NSValue* ptVal1 = [body.points objectAtIndex:(idx + 1) % body.points.count];
            
            CGPoint pt0 = [node convertToWorldSpace:[ptVal0 pointValue]];
            CGPoint pt1 = [node convertToWorldSpace:[ptVal1 pointValue]];
            
            float distance = distanceFromLineSegment(pt0, pt1, pos);
            
            if (distance <= kCCBPhysicsLineSegmFuzz)
            {
                return idx;
            }
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
    
    int newNumPts = cpConvexHull(numPts, verts, verts, NULL, 0.0f);
    
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
    
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    int handleIdx = [self handleIndexForPos:pos];
    int lineIdx = [self lineSegmIndexForPos:pos];
    
    _mouseDownPos = pos;
    _mouseDownInHandle = handleIdx;
    
    if (handleIdx != -1)
    {
        if (body.bodyShape ==  kCCBPhysicsBodyShapePolygon)
        {
            _handleStartPos = [[self.selectedNodePhysicsBody.points objectAtIndex:handleIdx] pointValue];
        }
        else if (body.bodyShape == kCCBPhysicsBodyShapeCircle)
        {
            if (handleIdx == 0)
            {
                _handleStartPos = [[self.selectedNodePhysicsBody.points objectAtIndex:0] pointValue];
            }
            else
            {
                _handleStartPos = ccp(body.cornerRadius, 0);
            }
        }
        
        return YES;
    }
    else if (lineIdx != -1)
    {
        // Add new control point
        [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*points"];
        
        CGPoint localPos = [node convertToNodeSpace:pos];
        
        NSMutableArray* points = [self.selectedNodePhysicsBody.points mutableCopy];
        [points insertObject:[NSValue valueWithPoint:localPos] atIndex:lineIdx + 1];
        self.selectedNodePhysicsBody.points = points;
        
        // Set this point as edited
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
    
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    if (_mouseDownInHandle != -1)
    {
        [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*points"];
        
        CGPoint delta = ccpSub(pos, _mouseDownPos);
        
        if (body.bodyShape == kCCBPhysicsBodyShapePolygon)
        {
            CGPoint newPos = [node convertToNodeSpace:ccpAdd(_mouseDownPos,delta)];
            
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
        }
        else if (body.bodyShape == kCCBPhysicsBodyShapeCircle)
        {
            if (_mouseDownInHandle == 0)
            {
                // Position handle
                CGPoint newPos = [node convertToNodeSpace:ccpAdd(_mouseDownPos,delta)];
                
                body.points = [NSArray arrayWithObject:[NSValue valueWithPoint:newPos]];
            }
            else if (_mouseDownInHandle == 1)
            {
                // Radius handle
                body.cornerRadius = _handleStartPos.x + delta.x / [self radiusScaleFactor];
                if (body.cornerRadius < 0) body.cornerRadius = 0;
            }
        }
        
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
    if (!self.editingPhysicsBody) return NO;
    
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    
    if (_mouseDownInHandle != -1 && body != nil)
    {
        if (body.bodyShape == kCCBPhysicsBodyShapePolygon)
        {
            [self makeConvexHull];
        }
        
        _mouseDownInHandle = -1;
        return YES;
    }
    
    return NO;
}

- (void) updatePhysicsEditor:(CCNode*) editorView
{
    float scale = [self radiusScaleFactor];
    float selectionBorderWidth = 1.0 / [CCDirector sharedDirector].contentScaleFactor;
    
    if (self.editingPhysicsBody)
    {
        CCNode* node = [AppDelegate appDelegate].selectedNode;
        
        // Position physic corners
        NodePhysicsBody* body = node.nodePhysicsBody;
        
        if (body.bodyShape == kCCBPhysicsBodyShapePolygon)
        {
            CGPoint* points = malloc(sizeof(CGPoint)*body.points.count);
            
            int i = 0;
            for (NSValue* ptVal in body.points)
            {
                // Absolute handle position
                
                // TODO: Handle position scale
                CGPoint pt = [ptVal pointValue];
                pt = [node convertToWorldSpace:pt];
                
                points[i] = ccpRound(pt);
                
                CCSprite* handle = [CCSprite spriteWithImageNamed:@"select-physics-corner.png"];
                handle.position = pt;
                [editorView addChild:handle];
                i++;
            }
            
            CCDrawNode* drawing = [CCDrawNode node];
            [drawing drawPolyWithVerts:points count:body.points.count fillColor:[CCColor clearColor] borderWidth:selectionBorderWidth borderColor:[CCColor colorWithRed:1 green:1 blue:1 alpha:0.3]];
            
            [editorView addChild:drawing z:-1];
            
            free(points);
        }
        else if (body.bodyShape == kCCBPhysicsBodyShapeCircle)
        {
            CGPoint center = [[body.points objectAtIndex:0] pointValue];
            center = [node convertToWorldSpace:center];
            
            // TODO: Better handling of scale
            CGPoint edge = ccpAdd(center, ccp(body.cornerRadius * scale, 0));
            
            
            // Circle shape
            CGPoint* points = malloc(sizeof(CGPoint)*32);
            
            for (int i = 0; i < 32; i++)
            {
                float angle = (2.0f * M_PI * i)/32;
                CGPoint pt = ccp(cosf(angle), sinf(angle));
                pt = ccpMult(pt, scale * body.cornerRadius);
                pt = ccpAdd(pt, center);
                
                points[i] = pt;
            }
            
            CCDrawNode* drawing = [CCDrawNode node];
            [drawing drawPolyWithVerts:points count:32 fillColor:[CCColor clearColor] borderWidth:selectionBorderWidth borderColor:[CCColor colorWithRed:1 green:1 blue:1 alpha:0.3]];
            
            [editorView addChild:drawing z:-1];
            
            free(points);
            
            // Draw handles
            CCSprite* centerHandle = [CCSprite spriteWithImageNamed:@"select-physics-corner.png"];
            centerHandle.position = ccpRound(center);
            [editorView addChild:centerHandle];
            
            CCSprite* edgeHandle = [CCSprite spriteWithImageNamed:@"select-physics-corner.png"];
            edgeHandle.position = ccpRound(edge);
            [editorView addChild:edgeHandle];
        }
    }
}

- (float) radiusScaleFactor
{
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    float scale = 1;
    
    while (node != NULL)
    {
        scale *= node.scaleX;
        node = node.parent;
    }
    
    return scale;
}
@end
