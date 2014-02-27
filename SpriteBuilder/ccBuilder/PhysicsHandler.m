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
#import "SceneGraph.h"
#import "PolyDecomposition.h"
#import "AppDelegate.h"
#import "CCNode+NodeInfo.h"
#import "NodePhysicsBody.h"
#import "chipmunk.h"
#import "CocosScene.h"
#import "CCBUtil.h"
#import "CCSprite_Private.h"
#import "PlugInNode.h"
#import "CCBPhysicsPivotJoint.h"
#import "CCBGlobals.h"
#import "GeometryUtil.h"
#import "NSPasteboard+CCB.h"
#import "NSArray+Query.h"

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
    _mouseDownOutletHandle = -1;
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

    [[SceneGraph instance].joints fixupReferences];//Fixup references of Joints due to changing Physics Nodes.
    
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
   
    self.selectedNodePhysicsBody.points = [PolyDecomposition makeConvexHull:self.selectedNodePhysicsBody.points];
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
#pragma mark -
#pragma mark Dragging
#pragma mark -

- (BOOL)draggingEntered:(id <NSDraggingInfo>)sender pos:(CGPoint)pos result:(NSDragOperation*)result
{
    NSPasteboard* pb = [sender draggingPasteboard];

    if([[pb propertyTypes] containsObject:@"com.cocosbuilder.jointBody"])
    {
        _mouseDownOutletHandle = 0;//lie
        _mouseDragPos = pos;
        _dragType = OutletDragTypeInspector;
        *result = NSDragOperationGeneric;
    }

    return NO;
    
}

- (BOOL)draggingUpdated:(id <NSDraggingInfo>)sender pos:(CGPoint)pos result:(NSDragOperation*)result
{
    _mouseDragPos = pos;
    [self mouseDraggedJointOutlets];
    return NO;
    
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    if(_mouseDownOutletHandle != -1)
    {
        //Cleanup
        _mouseDownOutletHandle = -1;
        _currentBodyTargeted = nil;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender pos:(CGPoint)pos
{
    if(_mouseDownOutletHandle != -1)
    {
        //Cleanup
        _mouseDownOutletHandle = -1;
        _currentBodyTargeted = nil;
    }

    
}



#pragma mark -
#pragma mark Joints
#pragma mark -

-(CCNode*)currentBodyTarget
{
    return _currentBodyTargeted;
}

-(void)findPhysicsNodes:(CCNode*)node nodes:(NSMutableArray*)nodes
{
    if(node.nodePhysicsBody)
    {
        [nodes addObject:node];
    }
    
    for (CCNode * child in node.children) {
        [self findPhysicsNodes:child nodes:nodes];
    }
}


-(void)mouseDraggedJointOutlets
{
    SceneGraph * g = [SceneGraph instance];
    
    NSMutableArray * physicsNodes = [NSMutableArray array];
    [self findPhysicsNodes:g.rootNode nodes:physicsNodes];
    
    _currentBodyTargeted = nil;
    
    //Find bodies we're inside the physics poly of.
    NSMutableArray * possibleBodies = [NSMutableArray array];
    for (CCNode * physicsNode in physicsNodes)
    {
        CGPoint testPoint = [physicsNode convertToNodeSpace:_mouseDragPos];
        if([GeometryUtil pointInRegion:testPoint poly:physicsNode.nodePhysicsBody.points])
        {
            [possibleBodies addObject:physicsNode];
        }
    }
    
    //Select the one we're closest too.

    for (CCNode * body in possibleBodies) {
        if(_currentBodyTargeted == nil)
            _currentBodyTargeted = body;
        else
        {
            CGPoint loc1 = [body convertToNodeSpaceAR:_mouseDragPos];
            CGPoint loc2 = [_currentBodyTargeted convertToNodeSpaceAR:_mouseDragPos];
            
            if(ccpDistance(CGPointZero, loc1) < ccpDistance(CGPointZero, loc2))
            {
                _currentBodyTargeted = body;
            }
        }
    }
}


#pragma mark - Mouse


- (BOOL)rightMouseDown:(CGPoint)pos event:(NSEvent*)event
{
    
    return NO;
}

- (BOOL) mouseDown:(CGPoint)pos event:(NSEvent*)event
{
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    if (!self.editingPhysicsBody && !node.plugIn.isJoint) return NO;
    
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    
    int outletIdx   = node.plugIn.isJoint ? [(CCBPhysicsJoint*)node hitTestOutlet:pos] : -1;
    int handleIdx   = [self handleIndexForPos:pos];
    int lineIdx     = [self lineSegmIndexForPos:pos];
    
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
        [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*points+"];
        
        CGPoint localPos = [node convertToNodeSpace:pos];
        
        NSMutableArray* points = [self.selectedNodePhysicsBody.points mutableCopy];
        [points insertObject:[NSValue valueWithPoint:localPos] atIndex:lineIdx + 1];
        self.selectedNodePhysicsBody.points = points;
        
        // Set this point as edited
        _handleStartPos = localPos;
        _mouseDownInHandle = lineIdx + 1;
        
        return YES;
    }
    else if(outletIdx != -1)
    {
        _currentJoint = (CCBPhysicsJoint*)node;
        
        _mouseDownOutletHandle = outletIdx;
        [_currentJoint setOutletStatus:outletIdx value:YES];
        _mouseDragPos = pos;
        _dragType = OutletDragTypeStage;
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
    _mouseDragPos = pos;
    
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    if (!self.editingPhysicsBody && !node.plugIn.isJoint) return NO;
    
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    
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
    else if(_mouseDownOutletHandle != -1)
    {
        [self mouseDraggedJointOutlets];
        return YES;
    }
    else
    {
        // Not doing any physics editing
        return NO;
    }
}



- (BOOL) rightMouseUp:(CGPoint)pos event:(NSEvent*)event
{   
    if (!self.editingPhysicsBody) return NO;
 
    int handleIdx = [self handleIndexForPos:pos];
    
    if(handleIdx != -1 && self.selectedNodePhysicsBody.points.count > 3)
    {
        [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*P*points-"];
        NSMutableArray* points = [self.selectedNodePhysicsBody.points mutableCopy];
        [points removeObjectAtIndex:handleIdx];
        self.selectedNodePhysicsBody.points = points;
        
        return YES;
    }

    
    return NO;
    
}

- (BOOL) mouseUp:(CGPoint)pos event:(NSEvent*)event
{
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    if (!self.editingPhysicsBody && !node.plugIn.isJoint) return NO;
    
    NodePhysicsBody* body = self.selectedNodePhysicsBody;
    
    if (_mouseDownInHandle != -1 && body != nil)
    {
        _mouseDownInHandle = -1;
        return YES;
    }
    
    if(_mouseDownOutletHandle != BodyIndexUnknown)
    {
        CCNode* node = [AppDelegate appDelegate].selectedNode;
        CCBPhysicsJoint * joint = (CCBPhysicsJoint*)node;
        
        if(_currentBodyTargeted)
        {
            [self assignBodyToJoint:_currentBodyTargeted toJoint:joint withIdx:_mouseDownOutletHandle];
        }

        //Cleanup
        _mouseDownOutletHandle = -1;
        [joint refreshOutletStatus];
        _currentBodyTargeted = nil;
        
        return YES;
    }
    
    return NO;
}

- (void) assignBodyToJoint:(CCNode*)body toJoint:(CCBPhysicsJoint*)joint withIdx:(BodyIndex)idx
{
    if(idx == BodyIndexA)
    {
        joint.bodyA = _currentBodyTargeted;
        [[AppDelegate appDelegate] refreshProperty:@"bodyA"];
    }
    else
    {
        joint.bodyB = _currentBodyTargeted;
        [[AppDelegate appDelegate] refreshProperty:@"bodyB"];
    }
    [joint refreshOutletStatus];
}

- (void)renderPhysicsBody:(CCNode *)node editorView:(CCNode *)editorView
{
    float scale = [self radiusScaleFactor];
    float selectionBorderWidth = 1.0 / [CCDirector sharedDirector].contentScaleFactor;
    
    
    // Position physic corners
    NodePhysicsBody* body = node.nodePhysicsBody;
    
    if (body.bodyShape == kCCBPhysicsBodyShapePolygon)
    {
        
        //Draw corner points.
        int i = 0;
        for (NSValue* ptVal in body.points)
        {
            // Absolute handle position
            
            // TODO: Handle position scale
            CGPoint pt = [ptVal pointValue];
            pt = [node convertToWorldSpace:pt];
            
            CCSprite* handle = [CCSprite spriteWithImageNamed:@"select-physics-corner.png"];
            handle.position = pt;
            [editorView addChild:handle];
            i++;
        }
        
        
        //Draw concave polys
        NSArray * polygons;
        bool success = [PolyDecomposition bayazitDecomposition:body.points outputPoly:&polygons];
        
        if(success)
        {
            for (NSArray * poly in polygons)
            {
                CGPoint* points = malloc(sizeof(CGPoint)*poly.count);
                int i = 0;
                for (NSValue* ptVal in poly)
                {
                    // Absolute handle position
                    
                    // TODO: Handle position scale
                    CGPoint pt = [ptVal pointValue];
                    pt = [node convertToWorldSpace:pt];
                    points[i] = ccpRound(pt);
                    i++;
                }
                
                CCDrawNode* drawing = [CCDrawNode node];
                
                
                [drawing drawPolyWithVerts:points count:poly.count fillColor:[CCColor clearColor] borderWidth:selectionBorderWidth/2 borderColor:[CCColor colorWithRed:1 green:1 blue:1 alpha:0.3]];
                
                [editorView addChild:drawing z:-1];
                
                free(points);
            }
        }
        
        
        //Draw Poly Outline
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
                i++;
            }
            
            CCDrawNode* drawing = [CCDrawNode node];
            
            
            [drawing drawPolyWithVerts:points count:body.points.count fillColor:[CCColor clearColor] borderWidth:selectionBorderWidth borderColor:[CCColor colorWithRed:1 green:1 blue:1 alpha:0.7]];
            
            [editorView addChild:drawing z:-1];
            
            free(points);
        }
        
        //highlight intersecting segments.
        {
            NSArray * intersectingSegments;
            if([PolyDecomposition intersectingLines:body.points outputSegments:&intersectingSegments])
            {
                for(int i = 0; i < intersectingSegments.count; i+=2)
                {
                    NSPoint ptA = [intersectingSegments[i] pointValue];
                    NSPoint ptB = [intersectingSegments[i+1] pointValue];
                    
                    ptA = [node convertToWorldSpace:ptA];
                    ptB = [node convertToWorldSpace:ptB];
                    
                    
                    CCDrawNode* drawing = [CCDrawNode node];
                    [drawing drawSegmentFrom:ptA to:ptB radius:1 color:[CCColor colorWithRed:1 green:.3 blue:.3 alpha:1.0]];
                    
                    [editorView addChild:drawing z:-1];
                }
            }
        }
        
        //highligh Acute Corners
        {
            NSArray * acuteCorners;
            if([PolyDecomposition acuteCorners:body.points outputSegments:&acuteCorners])
            {
                for(int i = 0; i < acuteCorners.count; i+=3)
                {
                    NSPoint ptA = [acuteCorners[i] pointValue];
                    NSPoint ptB = [acuteCorners[i+1] pointValue];
                    NSPoint ptC = [acuteCorners[i+2] pointValue];
                    
                    ptA = [node convertToWorldSpace:ptA];
                    ptB = [node convertToWorldSpace:ptB];
                    ptC = [node convertToWorldSpace:ptC];
                    
                    
                    CCDrawNode* drawing = [CCDrawNode node];
                    [drawing drawSegmentFrom:ptA to:ptB radius:1 color:[CCColor colorWithRed:1 green:.3 blue:.3 alpha:1.0]];
                    [drawing drawSegmentFrom:ptB to:ptC radius:1 color:[CCColor colorWithRed:1 green:.3 blue:.3 alpha:1.0]];
                    [editorView addChild:drawing z:-1];
                }
            }
        }
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

- (void) updatePhysicsEditor:(CCNode*) editorView
{
   
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    
    if(node.plugIn.isJoint)
    {
        CCBPhysicsJoint * joint = (CCBPhysicsJoint*)node;
        joint.isSelected = YES;
        
        if(_mouseDownOutletHandle != -1 && _dragType == OutletDragTypeStage)
        {
            CGPoint fromPt = [joint outletWorldPos:_mouseDownOutletHandle];
            
            CCDrawNode* drawing = [CCDrawNode node];
            [drawing drawSegmentFrom:fromPt to:_mouseDragPos radius:.5 color:[CCColor blackColor]];
            [editorView addChild:drawing z:-1];
        }
        
        if(_currentBodyTargeted)
        {
            [self renderPhysicsBody:_currentBodyTargeted editorView:editorView];
        }
    }
    else if (self.editingPhysicsBody)
    {
        [self renderPhysicsBody:node editorView:editorView];
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
