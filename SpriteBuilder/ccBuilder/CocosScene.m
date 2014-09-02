/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2011 Viktor Lidholt
 * Copyright (c) 2012 Zynga Inc.
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

#import "CocosScene.h"
#import "CCBGlobals.h"
#import "SceneGraph.h"
#import "AppDelegate.h"
#import "CCBReaderInternalV1.h"
#import "NodeInfo.h"
#import "PlugInManager.h"
#import "PlugInNode.h"
#import "RulersLayer.h"
#import "GuidesLayer.h"
#import "NotesLayer.h"
#import "SnapLayer.h"
#import "CCBTransparentWindow.h"
#import "CCBTransparentView.h"
#import "PositionPropertySetter.h"
#import "CCBGLView.h"
#import "MainWindow.h"
#import "CCNode+NodeInfo.h"
#import "SequencerHandler.h"
#import "SequencerSequence.h"
#import "SequencerNodeProperty.h"
#import "SequencerKeyframe.h"
#import "Tupac.h"
#import "PhysicsHandler.h"
#import "CCBUtil.h"
#import "CCTextureCache.h"
#import "NSArray+Query.h"
#import "GeometryUtil.h"
#import "NSPasteboard+CCB.h"

#define kCCBSelectionOutset 3
#define kCCBSinglePointSelectionRadius 23
#define kCCBAnchorPointRadius 3
#define kCCBTransformHandleRadius 5

static CocosScene* sharedCocosScene;
static NSString * kZeroContentSizeImage = @"sel-round.png";

@implementation CocosScene

@synthesize bgLayer;
@synthesize anchorPointCompensationLayer;
@synthesize rootNode;
@synthesize isMouseTransforming;
@synthesize scrollOffset;
@dynamic    currentTool;
@synthesize guideLayer;
@synthesize rulerLayer;
@synthesize notesLayer;
@synthesize snapLayer;
@synthesize physicsLayer;

+(id) sceneWithAppDelegate:(AppDelegate*)app
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	CocosScene *layer = [[CocosScene alloc] initWithAppDelegate:app];
    sharedCocosScene = layer;
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

+ (CocosScene*) cocosScene
{
	WARN(sharedCocosScene, @"sharedCocosScene is nil");
    return sharedCocosScene;
}

-(void) setupEditorNodes
{
    // Rulers
    rulerLayer = [RulersLayer node];
    [self addChild:rulerLayer z:7];
    
    // Guides
    guideLayer = [GuidesLayer node];
    [self addChild:guideLayer z:3];
    
    // Sticky notes
    notesLayer = [NotesLayer node];
    [self addChild:notesLayer z:7];
    
    // Snapping
    snapLayer = [SnapLayer node];
    [self addChild:snapLayer z:4];
    
    // Selection layer
    selectionLayer = [CCNode node];
    selectionLayer.name = @"selectionLayer";
    [self addChild:selectionLayer z:5];
    
    // Physics layer
    physicsLayer = [CCNode node];
    physicsLayer.name = @"physicsLayer";
    [self addChild:physicsLayer z:6];
    
    // Border layer
    borderLayer = [CCNode node];
    [self addChild:borderLayer z:1];
	
	CCColor* borderColor = [CCColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.7];
    
    borderBottom = [CCNodeColor nodeWithColor:borderColor];
    borderTop = [CCNodeColor nodeWithColor:borderColor];
    borderLeft = [CCNodeColor nodeWithColor:borderColor];
    borderRight = [CCNodeColor nodeWithColor:borderColor];
    
    borderBottom.userInteractionEnabled = NO;
    borderTop.userInteractionEnabled = NO;
    borderLeft.userInteractionEnabled = NO;
    borderRight.userInteractionEnabled = NO;
    
    [borderLayer addChild:borderBottom];
    [borderLayer addChild:borderTop];
    [borderLayer addChild:borderLeft];
    [borderLayer addChild:borderRight];
    
    borderDevice = [CCSprite node];
    [borderLayer addChild:borderDevice z:1];
    
    // Gray background
    bgLayer = [CCNodeColor nodeWithColor:[CCColor grayColor] width:4096 height:4096];
    bgLayer.position = ccp(0,0);
    bgLayer.anchorPoint = ccp(0,0);
    bgLayer.userInteractionEnabled = NO;
    [self addChild:bgLayer z:-1];
    
    // Black content layer
    stageBgLayer = [CCNodeColor nodeWithColor:[CCColor blackColor] width:0 height:0];
    stageBgLayer.anchorPoint = ccp(0.5,0.5);
    stageBgLayer.userInteractionEnabled = NO;
    stageBgLayer.name = @"stageBgLayer";
    //stageBgLayer.ignoreAnchorPointForPosition = NO;
    [self addChild:stageBgLayer z:0];
    
    contentLayer = [CCNode node];
    contentLayer.name = @"contentLayer";
    contentLayer.contentSizeType = CCSizeTypeNormalized;
    contentLayer.contentSize = CGSizeMake(1, 1);
    
    anchorPointCompensationLayer = [CCNode node];
    anchorPointCompensationLayer.contentSizeType = CCSizeTypeNormalized;
    anchorPointCompensationLayer.contentSize = CGSizeMake(1, 1);
    
    [stageBgLayer addChild:anchorPointCompensationLayer];
    [anchorPointCompensationLayer addChild:contentLayer];
    
    stageJointsLayer = [CCNode node];
    stageJointsLayer.name = @"stageJointsLayer";
    stageJointsLayer.anchorPoint = ccp(0.5,0.5);
    stageJointsLayer.userInteractionEnabled = NO;
     [self addChild:stageJointsLayer z:1];
    
    // Joints Layer
    jointsLayer = [CCNode node];
    jointsLayer.name = @"jointsLayer";
    jointsLayer.contentSizeType = CCSizeTypeNormalized;
    jointsLayer.contentSize = CGSizeMake(1, 1);
    [stageJointsLayer addChild:jointsLayer];

}

- (void) setStageBorder:(int)type
{
    borderDevice.visible = NO;
    
    if (stageBgLayer.contentSize.width == 0 || stageBgLayer.contentSize.height == 0)
    {
        type = kCCBBorderNone;
        stageBgLayer.visible = NO;
    }
    else
    {
        stageBgLayer.visible = YES;
    }
    
    if (type == kCCBBorderDevice)
    {
        [borderBottom setOpacity:1.0f];
        [borderTop setOpacity:1.0f];
        [borderLeft setOpacity:1.0f];
        [borderRight setOpacity:1.0f];
        
        CCTexture* deviceTexture = NULL;
        BOOL rotateDevice = NO;
        
        int devType = [appDelegate orientedDeviceTypeForSize:stageBgLayer.contentSize];
        if (devType == kCCBCanvasSizeIPhonePortrait)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-iphone.png"];
            rotateDevice = NO;
        }
        else if (devType == kCCBCanvasSizeIPhoneLandscape)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-iphone.png"];
            rotateDevice = YES;
        }
        if (devType == kCCBCanvasSizeIPhone5Portrait)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-iphone5.png"];
            rotateDevice = NO;
        }
        else if (devType == kCCBCanvasSizeIPhone5Landscape)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-iphone5.png"];
            rotateDevice = YES;
        }
        else if (devType == kCCBCanvasSizeIPadPortrait)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-ipad.png"];
            rotateDevice = NO;
        }
        else if (devType == kCCBCanvasSizeIPadLandscape)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-ipad.png"];
            rotateDevice = YES;
        }
        else if (devType == kCCBCanvasSizeFixedLandscape)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-fixed.png"];
            rotateDevice = NO;
        }
        else if (devType == kCCBCanvasSizeFixedPortrait)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-fixed.png"];
            rotateDevice = YES;
        }
        else if (devType == kCCBCanvasSizeAndroidXSmallPortrait)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-android-xsmall.png"];
            rotateDevice = NO;
        }
        else if (devType == kCCBCanvasSizeAndroidXSmallLandscape)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-android-xsmall.png"];
            rotateDevice = YES;
        }
        else if (devType == kCCBCanvasSizeAndroidSmallPortrait)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-android-small.png"];
            rotateDevice = NO;
        }
        else if (devType == kCCBCanvasSizeAndroidSmallLandscape)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-android-small.png"];
            rotateDevice = YES;
        }
        else if (devType == kCCBCanvasSizeAndroidMediumPortrait)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-android-medium.png"];
            rotateDevice = NO;
        }
        else if (devType == kCCBCanvasSizeAndroidMediumLandscape)
        {
            deviceTexture = [[CCTextureCache sharedTextureCache] addImage:@"frame-android-medium.png"];
            rotateDevice = YES;
        }
        
        if (deviceTexture)
        {
            if (rotateDevice) borderDevice.rotation = 90;
            else borderDevice.rotation = 0;
            
            borderDevice.texture = deviceTexture;
            borderDevice.textureRect = CGRectMake(0, 0, deviceTexture.contentSize.width, deviceTexture.contentSize.height);
            
            borderDevice.visible = YES;
        }
        borderLayer.visible = YES;
    }
    else if (type == kCCBBorderTransparent)
    {
        [borderBottom   setOpacity:0.5f];
        [borderTop      setOpacity:0.5f];
        [borderLeft     setOpacity:0.5f];
        [borderRight    setOpacity:0.5f];
        
        borderLayer.visible = YES;
    }
    else if (type == kCCBBorderOpaque)
    {
        [borderBottom setOpacity:1.0f];
        [borderTop setOpacity:1.0f];
        [borderLeft setOpacity:1.0f];
        [borderRight setOpacity:1.0f];
        borderLayer.visible = YES;
    }
    else
    {
        borderLayer.visible = NO;
    }
    
    stageBorderType = type;
    
    [appDelegate updateCanvasBorderMenu];
}

- (int) stageBorder
{
    return stageBorderType;
}

- (void) setStageColor: (int) type forDocDimensionsType: (int) docDimensionsType
{
    CCColor *color;
    switch (type)
    {
        case kCCBCanvasColorBlack:
            color = [CCColor blackColor];
            break;
        case kCCBCanvasColorWhite:
            color = [CCColor whiteColor];
            break;
        case kCCBCanvasColorGray:
            color = [CCColor grayColor];
            break;
        case kCCBCanvasColorOrange:
            color = [CCColor orangeColor];
            break;
        case kCCBCanvasColorGreen:
            color = [CCColor greenColor];
            break;
        default:
            NSAssert (NO, @"Illegal stage color");
    }
    NSAssert(color != nil, @"No stage color");

    if (docDimensionsType == kCCBDocDimensionsTypeNode)
    {
        bgLayer.color = color;
        stageBgLayer.color = [CCColor blackColor];
    }
    else
    {
        bgLayer.color = [CCColor grayColor];
        stageBgLayer.color = color;
    }
}

- (void) setupDefaultNodes
{
}

#pragma mark Stage properties

- (void) setStageSize: (CGSize) size centeredOrigin:(BOOL)centeredOrigin
{
    snapLinesNeedUpdate = YES; // This will cause the snap/alignment lines to update after undo/redo are called
    stageBgLayer.contentSize = size;
    stageJointsLayer.contentSize = size;

    
    if (centeredOrigin)
    {
        contentLayer.position = ccp(size.width/2, size.height/2);
        jointsLayer.position = contentLayer.position;
    }
    else
    {
        contentLayer.position = ccp(0,0);
        jointsLayer.position = contentLayer.position;
    }
    
    [self setStageBorder:stageBorderType];
    
    
    if (renderedScene)
    {
        [self removeChild:renderedScene cleanup:YES];
        renderedScene = NULL;
    }
    
    if (size.width > 0 && size.height > 0 && size.width <= 1024 && size.height <= 1024)
    {
        // Use a new autorelease pool
        // Otherwise, two successive calls to the running method (_cmd) cause a crash!
        @autoreleasepool {
        
            renderedScene = [CCRenderTexture renderTextureWithWidth:size.width height:size.height];
            renderedScene.anchorPoint = ccp(0.5f,0.5f);
            [self addChild:renderedScene];

        }
    }
}

- (CGSize) stageSize
{
    return stageBgLayer.contentSize;
}

- (BOOL) centeredOrigin
{
    return (contentLayer.position.x != 0);
}

- (void) setStageZoom:(float) zoom
{
    float zoomFactor = zoom/stageZoom;
    
    scrollOffset = ccpMult(scrollOffset, zoomFactor);
    
    stageBgLayer.scale = zoom;
    borderDevice.scale = zoom;
    stageJointsLayer.scale = zoom;
    
    stageZoom = zoom;
    snapLinesNeedUpdate = YES;
}

- (float) stageZoom
{
    return stageZoom;
}

#pragma mark Extra properties

- (void) setupExtraPropsForNode:(CCNode*) node
{
    [node setExtraProp:[NSNumber numberWithInt:-1] forKey:@"tag"];
    [node setExtraProp:[NSNumber numberWithBool:YES] forKey:@"lockedScaleRatio"];
    
    [node setExtraProp:@"" forKey:@"customClass"];
    [node setExtraProp:[NSNumber numberWithInt:0] forKey:@"memberVarAssignmentType"];
    [node setExtraProp:@"" forKey:@"memberVarAssignmentName"];
    
    [node setExtraProp:[NSNumber numberWithBool:YES] forKey:@"isExpanded"];
}

#pragma mark Replacing content

- (void) replaceSceneNodes:(SceneGraph*)sceneGraph
{
    [contentLayer removeChild:rootNode cleanup:YES];
    [jointsLayer removeAllChildrenWithCleanup:YES];
    
    self.rootNode = sceneGraph.rootNode;
    
    if (sceneGraph.rootNode)
        [contentLayer addChild:sceneGraph.rootNode];
    
    if(sceneGraph.joints.node)
        [jointsLayer addChild:sceneGraph.joints.node];
}

#pragma mark Handle selections

- (BOOL) selectedNodeHasReadOnlyProperty:(NSString*)prop
{
    CCNode* selectedNode = appDelegate.selectedNode;
    
    if (!selectedNode) return NO;
    NodeInfo* info = selectedNode.userObject;
    PlugInNode* plugIn = info.plugIn;
    
    NSDictionary* propInfo = [plugIn.nodePropertiesDict objectForKey:prop];
    return [[propInfo objectForKey:@"readOnly"] boolValue];
}


-(void)renderBorder:(CCNode*)node
{
	// Selection corners in world space
	CGPoint points[4]; //{bl,br,tr,tl}

	
	[self getCornerPointsForNode:node withPoints:points];
	
	
	CCSprite* blSprt = [CCSprite spriteWithImageNamed:@"select-corner.png"];
	CCSprite* brSprt = [CCSprite spriteWithImageNamed:@"select-corner.png"];
	CCSprite* tlSprt = [CCSprite spriteWithImageNamed:@"select-corner.png"];
	CCSprite* trSprt = [CCSprite spriteWithImageNamed:@"select-corner.png"];
	
	
	blSprt.position = points[0];
	brSprt.position = points[1];
	trSprt.position = points[2];
	tlSprt.position = points[3];
	
	[selectionLayer addChild:blSprt];
	[selectionLayer addChild:brSprt];
	[selectionLayer addChild:tlSprt];
	[selectionLayer addChild:trSprt];
	
	CCDrawNode* drawing = [CCDrawNode node];
	
	float borderWidth = 1.0 / [CCDirector sharedDirector].contentScaleFactor;
	
	[drawing drawPolyWithVerts:points count:4 fillColor:[CCColor clearColor] borderWidth:borderWidth borderColor:[CCColor colorWithRed:1 green:1 blue:1 alpha:0.3]];
	
	[selectionLayer addChild:drawing z:-1];

}

- (void) updateSelection
{
    NSArray* nodes = appDelegate.selectedNodes;
    
    uint overTypeField = 0x0;
    
    if (nodes.count > 0)
    {
        for (CCNode* node in nodes)
        {
            //Don't display if special case rendering flag is present.
            if([[node extraPropForKey:@"disableStageRendering"] boolValue])
            {
                continue;
            }
            
            if(node.locked)
            {
                //Locked nodes shouldn't render
                continue;
            }
            
            
            {
                CGPoint localAnchor = ccp(node.anchorPoint.x * node.contentSizeInPoints.width,
                                          node.anchorPoint.y * node.contentSizeInPoints.height);
                
                CGPoint anchorPointPos = ccpRound([node convertToWorldSpace:localAnchor]);
                
                CCSprite* anchorPointSprite = [CCSprite spriteWithImageNamed:@"select-pt.png"];
                anchorPointSprite.position = anchorPointPos;
                [selectionLayer addChild:anchorPointSprite z:1];
                
                CGPoint points[4]; //{bl,br,tr,tl}
                BOOL isContentSizeZero = NO;
                
                if (node.contentSize.width > 0 && node.contentSize.height > 0)
                {
                    // Selection corners in world space
                    
                    CCSprite* blSprt = [CCSprite spriteWithImageNamed:@"select-corner.png"];
                    CCSprite* brSprt = [CCSprite spriteWithImageNamed:@"select-corner.png"];
                    CCSprite* tlSprt = [CCSprite spriteWithImageNamed:@"select-corner.png"];
                    CCSprite* trSprt = [CCSprite spriteWithImageNamed:@"select-corner.png"];
                    
                    [self getCornerPointsForNode:node withPoints:points];
                    
                    blSprt.position = points[0];
                    brSprt.position = points[1];
                    trSprt.position = points[2];
                    tlSprt.position = points[3];
                    
                    [selectionLayer addChild:blSprt];
                    [selectionLayer addChild:brSprt];
                    [selectionLayer addChild:tlSprt];
                    [selectionLayer addChild:trSprt];
                    
                    CCDrawNode* drawing = [CCDrawNode node];
                
                    float borderWidth = 1.0 / [CCDirector sharedDirector].contentScaleFactor;
                    
                    [drawing drawPolyWithVerts:points count:4 fillColor:[CCColor clearColor] borderWidth:borderWidth borderColor:[CCColor colorWithRed:1 green:1 blue:1 alpha:0.3]];
                    
                    [selectionLayer addChild:drawing z:-1];
                }
                else
                {
                    isContentSizeZero = YES;
                    CGPoint pos = [node convertToWorldSpace: ccp(0,0)];
                    

                    CCSprite* sel = [CCSprite spriteWithImageNamed:kZeroContentSizeImage];
                    sel.anchorPoint = ccp(0.5f, 0.5f);
                    sel.position = pos;
                    [selectionLayer addChild:sel];
                    
                    [self getCornerPointsForZeroContentSizeNode:node withImageContentSize:sel.contentSizeInPoints withPoints:points];
                }
				
				
                if(!isContentSizeZero && !(overTypeField & kCCBToolAnchor) && currentMouseTransform == kCCBTransformHandleNone)
                {
                    if([self isOverAnchor:node withPoint:mousePos])
                    {
                        overTypeField |= kCCBToolAnchor;
                    }
                }

                if(!isContentSizeZero && !(overTypeField & kCCBToolSkew) && currentMouseTransform == kCCBTransformHandleNone)
                {
                    if([self isOverSkew:node withPoint:mousePos withOrientation:&skewSegmentOrientation alongAxis:&skewSegment])
                    {
                        overTypeField |= kCCBToolSkew;
                    }
                }

                if(!(overTypeField & kCCBToolRotate) && currentMouseTransform == kCCBTransformHandleNone)
                {
                    if([self isOverRotation:mousePos withPoints:points withCorner:&cornerIndex withOrientation:&cornerOrientation])
                    {
                        overTypeField |= kCCBToolRotate;
                    }
                }

                if(!(overTypeField & kCCBToolScale) && currentMouseTransform == kCCBTransformHandleNone)
                {
                   if([self isOverScale:mousePos withPoints:points withCorner:&cornerIndex withOrientation:&cornerOrientation])
                   {
                       overTypeField |= kCCBToolScale;
                   }
                }
                
                
                if(!(overTypeField & kCCBToolTranslate) && currentMouseTransform == kCCBTransformHandleNone)
                {
                    if([self isOverContentBorders:mousePos withPoints:points])
                    {
                        overTypeField |= kCCBToolTranslate;
                    }
                }
            }
        }
    }
    
    
    
    if(currentMouseTransform == kCCBTransformHandleNone)
    {
        if(!(overTypeField & currentTool))
        {
            self.currentTool = kCCBToolSelection;
        }
        
        
        if (overTypeField)
        {
            for(int i = 0; (1 << i) != kCCBToolMax; i++)
            {
                CCBTool type = (1 << i);
                if(overTypeField & type && self.currentTool > type)
                {
                    self.currentTool = type; 
                    break;
                }
            }
        }
    }
}

- (void) selectBehind
{
    if (currentNodeAtSelectionPtIdx < 0) return;
    
    currentNodeAtSelectionPtIdx -= 1;
    if (currentNodeAtSelectionPtIdx < 0)
    {
        currentNodeAtSelectionPtIdx = (int)[nodesAtSelectionPt count] -1;
    }
    
    [appDelegate setSelectedNodes:[NSArray arrayWithObject:[nodesAtSelectionPt objectAtIndex:currentNodeAtSelectionPtIdx]]];
}

//{bl,br,tr,tl}
-(void)getCornerPointsForNode:(CCNode*)node withPoints:(CGPoint*)points
{
    // Selection corners in world space
    points[0] = ccpRound([node convertToWorldSpace: ccp(0,0)]);
    points[1] = ccpRound([node convertToWorldSpace: ccp(node.contentSizeInPoints.width,0)]);
    points[2] = ccpRound([node convertToWorldSpace: ccp(node.contentSizeInPoints.width,node.contentSizeInPoints.height)]);
    points[3] = ccpRound([node convertToWorldSpace: ccp(0,node.contentSizeInPoints.height)]);
  
}

//{bl,br,tr,tl}
-(void)getCornerPointsForZeroContentSizeNode:(CCNode*)node withImageContentSize:(CGSize)contentSize withPoints:(CGPoint*)points
{
    //Hard coded offst
    const CGPoint cornerPos = {11.0f,11.0f};
    
    CGPoint diaganol = ccp(contentSize.width/2, contentSize.height/2);
    diaganol = ccpSub(diaganol, cornerPos);
    CGPoint position  = [node convertToWorldSpace:ccp(0.0f,0.0f)];
    
    points[0] = ccpRound( ccpAdd(position, ccpMult(diaganol, -1.0f)));
    points[1] = ccpRound( ccpAdd(position,ccpRPerp(diaganol)));
    points[2] = ccpRound( ccpAdd(position,diaganol));
    points[3] = ccpRound( ccpAdd(position, ccpPerp(diaganol)));

}

- (BOOL) isOverAnchor:(CCNode*)node withPoint:(CGPoint)pt
{
    CGPoint localAnchor = ccp(node.anchorPoint.x * node.contentSizeInPoints.width,
                              node.anchorPoint.y * node.contentSizeInPoints.height);
    
    CGPoint center = [node convertToWorldSpace:localAnchor];

    if (ccpDistance(pt, center) < kCCBAnchorPointRadius)
        return YES;
    
    return NO;
}
- (BOOL) isOverSkew:(CCNode*)node withPoint:(CGPoint)pt withOrientation:(CGPoint*)orientation alongAxis:(int*)isXAxis  //{b,r,t,l}
{
    
    CGPoint points[4]; //{bl,br,tr,tl}
    [self getCornerPointsForNode:node withPoints:points];
    
    if([self isOverContentBorders:mousePos withPoints:points])
        return NO;
    
    for (int i = 0; i < 4; i++)
    {
        
        CGPoint p1 = points[i % 4];
        CGPoint p2 = points[(i + 1) % 4];
        CGPoint segment = ccpSub(p2, p1);
        CGPoint unitSegment = ccpNormalize(segment);

        const int kInsetFromEdge = 8;
        const float kDistanceFromSegment = 3.0f;
        
        if(ccpLength(segment) <= kInsetFromEdge * 2)
        {
            continue;//Its simply too small for Skew.
        }
        
        CGPoint adj1 = ccpAdd(p1, ccpMult(unitSegment, kInsetFromEdge));
        CGPoint adj2 = ccpSub(p2, ccpMult(unitSegment, kInsetFromEdge));
        
        
        CGPoint closestPoint = ccpClosestPointOnLine(adj1, adj2, pt);
        float dotProduct = ccpDot( ccpNormalize(ccpSub(adj1, adj2)),ccpNormalize(ccpSub(pt, closestPoint)));
        
        CGPoint vectorFromLine = ccpSub(pt, closestPoint);
        
        //Its close to the line, and perpendicular.
        if((ccpLength(vectorFromLine) < kDistanceFromSegment && fabsf(dotProduct) < 0.01f) ||
           (ccpLength(vectorFromLine) < 0.001 /*very small*/ && fabsf(dotProduct) == 1.0f) /*we're on the line*/)
        {
            CGPoint lockedVertex = [self vertexLocked:node.anchorPoint];
            if(i == lockedVertex.x || i == lockedVertex.y)
                continue;

            
            if(orientation)
           	 {
                *orientation = unitSegment;
            }
            
            if(isXAxis)
            {
                *isXAxis = i;
            }
            
            return YES;
        }
    }
    
    return NO;
}


- (BOOL) isOverContentBorders:(CGPoint)_mousePoint withPoints:(const CGPoint *)points /*{bl,br,tr,tl}*/ 
{
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    CGPathAddLines(mutablePath, nil, points, 4);
    CGPathCloseSubpath(mutablePath);
    BOOL result = CGPathContainsPoint(mutablePath, nil, _mousePoint, NO);
    CFRelease(mutablePath);
    return result;
    
}

- (BOOL) isOverScale:(CGPoint)_mousePos withPoints:(const CGPoint*)points/*{bl,br,tr,tl}*/  withCorner:(int*)_cornerIndex withOrientation:(CGPoint*)_orientation
{
    int lCornerIndex = -1;
    CGPoint orientation;
    float minDistance = INFINITY;
    
    for (int i = 0; i < 4; i++)
    {
        CGPoint p1 = points[i % 4];
        CGPoint p2 = points[(i + 1) % 4];
        CGPoint p3 = points[(i + 2) % 4];
        
        const float kDistanceToCorner = 8.0f;
        
        float distance = ccpLength(ccpSub(_mousePos, p2));
        
        if(distance < kDistanceToCorner  && distance < minDistance)
        {
            CGPoint segment1 = ccpSub(p2, p1);
            CGPoint segment2 = ccpSub(p2, p3);
    
            orientation = ccpNormalize(ccpAdd(segment1, segment2));
            lCornerIndex = (i + 1) % 4;
            minDistance = distance;

        }
        
    }
    
    if(lCornerIndex != -1)
    {
        if(_orientation)
        {
            *_orientation = orientation;
        }
        
        if(_cornerIndex)
        {
            *_cornerIndex = lCornerIndex;
        }
        return YES;
    }
    
    return NO;
    
}

- (BOOL) isOverRotation:(CGPoint)_mousePos withPoints:(const CGPoint*)points/*{bl,br,tr,tl}*/ withCorner:(int*)_cornerIndex withOrientation:(CGPoint*)orientation
{
    for (int i = 0; i < 4; i++)
    {
        CGPoint p1 = points[i % 4];
        CGPoint p2 = points[(i + 1) % 4];
        CGPoint p3 = points[(i + 2) % 4];

        CGPoint segment1 = ccpSub(p2, p1);
        CGPoint unitSegment1 = ccpNormalize(segment1);

        
        CGPoint segment2 = ccpSub(p2, p3);
        CGPoint unitSegment2 = ccpNormalize(segment2);
        
        const float kMinDistanceForRotation = 8.0f;
        const float kMaxDistanceForRotation = 25.0f;
       
        
        CGPoint mouseVector = ccpSub(_mousePos, p2);
        
        float dot1 = ccpDot(mouseVector, unitSegment1);
        float dot2 = ccpDot(mouseVector, unitSegment2);
        float distanceToCorner = ccpLength(mouseVector);
        
        if(dot1 > 0.0f && dot2 > 0.0f && distanceToCorner > kMinDistanceForRotation && distanceToCorner < kMaxDistanceForRotation)
        {
            if(_cornerIndex)
            {
                *_cornerIndex = (i + 1) % 4;
            }
            
            if(orientation)
            {
                *orientation = ccpNormalize(ccpAdd(unitSegment1, unitSegment2));
            }

            return YES;
        }
        
    }
    
    return NO;
}

-(void)findObjectsAtPoint:(CGPoint)point node:(CCNode*)node nodes:(NSMutableArray*)nodes
{
	if([node hitTestWithWorldPos:point])
	{
		[nodes addObject:node];
	}
    
    for (CCNode * child in node.children)
	{
        [self findObjectsAtPoint:point node:child nodes:nodes];
    }
}


- (CCNode*)findObjectAtPoint:(CGPoint)point ofTypes:(NSArray*)filterClassTypes
{
    SceneGraph * g = [SceneGraph instance];
    
    NSMutableArray * nodes = [NSMutableArray array];
	[self findObjectsAtPoint:point node:g.rootNode nodes:nodes];
	
	
    //Find bodies we're inside the physics poly of.


	[nodes filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CCNode * testNode, NSDictionary *bindings) {
		
		for (NSString * classTypeName in filterClassTypes) {

			Class classType = NSClassFromString(classTypeName);
			
			if([testNode isKindOfClass:classType])
				return YES;
		}
		
		return NO;
		
	}]];
	
	
	//Filder bodies that are children of CCBPCCBFiles
	[nodes removeObjectsInArray:[nodes where:^BOOL(CCNode* node, int idx) {
		CCNode * parent = node.parent;
		while (parent) {
			if([[[parent class] description] isEqualToString:@"CCBPCCBFile"])
				return YES;
			parent=parent.parent;
		}
		return NO;
	}]];
	
    
    //Select the one we're closest too.
    CCNode * currentBody;
    
    for (CCNode * body in nodes) {
        if(currentBody == nil)
            currentBody = body;
        else
        {
            CGPoint loc1 = [body convertToNodeSpaceAR:point];
            CGPoint loc2 = [currentBody convertToNodeSpaceAR:point];
            
            if(ccpDistance(CGPointZero, loc1) < ccpDistance(CGPointZero, loc2))
            {
                currentBody = body;
            }
        }
    }
    
    return currentBody;
}


#pragma mark Handle Drag Input

-(void)updateDragging
{
	if(effectSpriteDragging)
	{
		NSArray * classTypes = @[NSStringFromClass([CCSprite class])];
		
		CCNode * node = [[CocosScene cocosScene] findObjectAtPoint:effectSpriteDraggingLocation ofTypes:classTypes];
		if(node)
		{
			[self renderBorder:node];
		}
	}
	
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender pos:(CGPoint)pos
{
    NSDragOperation operation;
    if([appDelegate.physicsHandler draggingEntered:sender pos:pos result:&operation])
    {
        return operation;
    }
	
	NSPasteboard* pb = [sender draggingPasteboard];
    
    // Textures
	
	NSArray* pbSprites = [pb propertyListsForType:@"com.cocosbuilder.effectSprite"];

	if(pbSprites.count > 0)
	{
		effectSpriteDragging = YES;
		effectSpriteDraggingLocation = pos;
		return NSDragOperationGeneric;
	}
	
    return NSDragOperationGeneric;

}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender pos:(CGPoint)pos
{
    NSDragOperation operation;
    if([appDelegate.physicsHandler draggingUpdated:sender pos:pos result:&operation])
    {
        return operation;
    }
	
	effectSpriteDraggingLocation = pos;
    
    return NSDragOperationGeneric;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender pos:(CGPoint)pos
{
    [appDelegate.physicsHandler draggingExited:sender pos:pos];
	effectSpriteDragging = NO;
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    [appDelegate.physicsHandler draggingEnded:sender];
	effectSpriteDragging = NO;
	
}

#pragma mark Handle mouse input

- (CGPoint) convertToDocSpace:(CGPoint)viewPt
{
    return [contentLayer convertToNodeSpace:viewPt];
}

- (CGPoint) convertToViewSpace:(CGPoint)docPt
{
    return [contentLayer convertToWorldSpace:docPt];
}

- (NSString*) positionPropertyForSelectedNode
{
    NodeInfo* info = appDelegate.selectedNode.userObject;
    PlugInNode* plugIn = info.plugIn;
    
    return plugIn.positionProperty;
}

- (CGPoint) selectedNodePos
{
    if (!appDelegate.selectedNode) return CGPointZero;
    
    return NSPointToCGPoint([PositionPropertySetter positionForNode:appDelegate.selectedNode prop:[self positionPropertyForSelectedNode]]);
}



- (CCBTransformHandle) transformHandleUnderPt:(CGPoint)pt
{
    for (CCNode* node in appDelegate.selectedNodes)
    {
        if(node.locked)
            continue;
        
        transformScalingNode = node;
        
        BOOL isJoint = node.plugIn.isJoint;
        
        BOOL isContentSizeZero = NO;
        CGPoint points[4];
        
        
        if (transformScalingNode.contentSize.width == 0 || transformScalingNode.contentSize.height == 0)
        {
            isContentSizeZero = YES;
            CCSprite * sel = [CCSprite spriteWithImageNamed:kZeroContentSizeImage];
            [self getCornerPointsForZeroContentSizeNode:node withImageContentSize:sel.contentSize withPoints:points];
        }
        else
        {
            [self getCornerPointsForNode:node withPoints:points];
        }
        
        //NOTE The following return statements should go in order of the CCBTool enumeration.
        //kCCBToolAnchor
        if(!isJoint && !isContentSizeZero && [self isOverAnchor:node withPoint:pt])
            return kCCBTransformHandleAnchorPoint;
        
        if([self isOverContentBorders:pt withPoints:points])
            return kCCBTransformHandleDownInside;
        
        
        //kCCBToolScale
        if(!isJoint && [self isOverScale:pt withPoints:points withCorner:nil withOrientation:nil])
            return kCCBTransformHandleScale;
        
        //kCCBToolSkew
        if(!isJoint && !isContentSizeZero && [self isOverSkew:node withPoint:pt withOrientation:nil alongAxis:nil])
            return kCCBTransformHandleSkew;

        //kCCBToolRotate
        if(!isJoint && [self isOverRotation:pt withPoints:points withCorner:nil withOrientation:nil])
            return kCCBTransformHandleRotate;
        
    }
    
    transformScalingNode = NULL;
    return kCCBTransformHandleNone;
}

- (void) nodesUnderPt:(CGPoint)pt rootNode:(CCNode*) node nodes:(NSMutableArray*)nodes
{
    if (!node) return;
    
    NodeInfo* parentInfo = node.parent.userObject;
    PlugInNode* parentPlugIn = parentInfo.plugIn;
    if (parentPlugIn && !parentPlugIn.canHaveChildren) return;
    
    if ((node.contentSize.width == 0 || node.contentSize.height == 0) && !node.plugIn.isJoint)
    {
        CGPoint worldPos = [node.parent convertToWorldSpace:node.position];
        if (ccpDistance(worldPos, pt) < kCCBSinglePointSelectionRadius)
        {
            [nodes addObject:node];
        }
    }
    else
    {
        if ([node hitTestWithWorldPos:pt])
        {
            [nodes addObject:node];
        }
    }
    
    // Visit children
    for (int i = 0; i < [node.children count]; i++)
    {
        [self nodesUnderPt:pt rootNode:[node.children objectAtIndex:i] nodes:nodes];
    }
  
    //Don't select nodes that are locked or hidden.
    NSArray * selectableNodes = [nodes filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(CCNode * node, NSDictionary *bindings) {
        return !node.locked && !node.hidden && !node.parentHidden;
    }]];
    [nodes removeAllObjects];
    [nodes addObjectsFromArray:selectableNodes];

    
}

- (BOOL) isLocalCoordinateSystemFlipped:(CCNode*)node
{
    // TODO: Can this be done more efficiently?
    BOOL isMirroredX = NO;
    BOOL isMirroredY = NO;
    CCNode* nodeMirrorCheck = node;
    while (nodeMirrorCheck != rootNode && nodeMirrorCheck != NULL)
    {
        if (nodeMirrorCheck.scaleY < 0) isMirroredY = !isMirroredY;
        if (nodeMirrorCheck.scaleX < 0) isMirroredX = !isMirroredX;
        nodeMirrorCheck = nodeMirrorCheck.parent;
    }
    
    return (isMirroredX ^ isMirroredY);
}



- (void)rightMouseDown:(NSEvent *)event
{
    if (!appDelegate.hasOpenedDocument) return;
    
    CGPoint pos = [[CCDirectorMac sharedDirector] convertEventToGL:event];
    if ([appDelegate.physicsHandler rightMouseDown:pos event:event]) return;
    
}

- (void) mouseDown:(NSEvent *)event
{
    if (!appDelegate.hasOpenedDocument) return;
    
    CGPoint pos = [[CCDirectorMac sharedDirector] convertEventToGL:event];
    
    if ([notesLayer mouseDown:pos event:event]) return;
    if ([guideLayer mouseDown:pos event:event]) return;
    [snapLayer mouseDown:pos event:event];
    if ([appDelegate.physicsHandler mouseDown:pos event:event]) return;
    
    mouseDownPos = pos;
    
    // Handle grab tool
    if (currentTool == kCCBToolGrab || ([event modifierFlags] & NSCommandKeyMask))
    {

        self.currentTool = kCCBToolGrab;
        isPanning = YES;
        panningStartScrollOffset = scrollOffset;
        return;
    }
    
    // Find out which objects were clicked
    
    // Transform handles
    
    if (!appDelegate.physicsHandler.editingPhysicsBody)
    {
        CCBTransformHandle th = [self transformHandleUnderPt:pos];
        
        if (th == kCCBTransformHandleAnchorPoint)
        {
            // Anchor points are fixed for singel point nodes
            if (transformScalingNode.contentSizeInPoints.width == 0 || transformScalingNode.contentSizeInPoints.height == 0)
            {
                return;
            }
            
            BOOL readOnly = [[[transformScalingNode.plugIn.nodePropertiesDict objectForKey:@"anchorPoint"] objectForKey:@"readOnly"] boolValue];
            if (readOnly)
            {
                return;
            }
            
            // Transform anchor point
            currentMouseTransform = kCCBTransformHandleAnchorPoint;
            [transformScalingNode cacheStartTransformAndAnchor];
            return;
        }
        if(th == kCCBTransformHandleRotate && appDelegate.selectedNode != rootNode)
        {
            // Start rotation transform
            currentMouseTransform = kCCBTransformHandleRotate;
            transformStartRotation = transformScalingNode.rotation;
            return;
        }
        
        if (th == kCCBTransformHandleScale && appDelegate.selectedNode != rootNode)
        {
            // Start scale transform
            currentMouseTransform = kCCBTransformHandleScale;
            transformStartScaleX = [PositionPropertySetter scaleXForNode:transformScalingNode prop:@"scale"];
            transformStartScaleY = [PositionPropertySetter scaleYForNode:transformScalingNode prop:@"scale"];
            return;
            
        }
        if(th == kCCBTransformHandleSkew && appDelegate.selectedNode != rootNode)
        {
            currentMouseTransform = kCCBTransformHandleSkew;
            
            transformStartSkewX = transformScalingNode.skewX;
            transformStartSkewY = transformScalingNode.skewY;
            return;
            
        }
    }
    
    
    // Clicks inside objects
    [nodesAtSelectionPt removeAllObjects];
    
   
	[self nodesUnderPt:pos rootNode:rootNode nodes:nodesAtSelectionPt];
	
	[[jointsLayer.children.firstObject children] forEach:^(CCNode * jointNode, int idx) {
        [self nodesUnderPt:pos rootNode:jointNode nodes:nodesAtSelectionPt];
    }];

    currentNodeAtSelectionPtIdx = (int)[nodesAtSelectionPt count] -1;
    
    currentMouseTransform = kCCBTransformHandleNone;
    
    if (currentNodeAtSelectionPtIdx >= 0)
    {
        currentMouseTransform = kCCBTransformHandleDownInside;
    }
    else
    {
        // No clicked node
        if ([event modifierFlags] & NSShiftKeyMask)
        {
            // Ignore
            return;
        }
        else
        {
            // Deselect
            appDelegate.selectedNodes = NULL;
        }
    }
    
    return;
}



- (void) rightMouseUp:(NSEvent *)event
{
    if (!appDelegate.hasOpenedDocument) return;
    
    CGPoint pos = [[CCDirectorMac sharedDirector] convertEventToGL:event];
    
    if ([appDelegate.physicsHandler rightMouseUp:pos event:event]) return;
    
    
}

//0=bottom, 1=right  2=top 3=left
-(CGPoint)vertexLocked:(CGPoint)anchorPoint
{
    CGPoint vertexScaler = ccp(-1.0f,-1.0f);
    
    const float kTolerance = 0.01f;
    if(fabsf(anchorPoint.x) <= kTolerance)
    {
        vertexScaler.x = 3;
    }
    
    if(fabsf(anchorPoint.x) >=  1.0f - kTolerance)
    {
        vertexScaler.x = 1;
    }
    
    if(fabsf(anchorPoint.y) <= kTolerance)
    {
        vertexScaler.y = 0;
    }
    if(fabsf(anchorPoint.y) >=  1.0f - kTolerance)
    {
        vertexScaler.y = 2;
    }
    return vertexScaler;
}


-(CGPoint)vertexLockedScaler:(CGPoint)anchorPoint withCorner:(int) cornerSelected /*{bl,br,tr,tl} */
{
    CGPoint vertexScaler = {1.0f,1.0f};
    
    const float kTolerance = 0.01f;
    if(fabsf(anchorPoint.x) < kTolerance)
    {
        if(cornerSelected == 0 || cornerSelected == 3)
        {
            vertexScaler.x = 0.0f;
        }
    }
    if(fabsf(anchorPoint.x) >  1.0f - kTolerance)
    {
        if(cornerSelected == 1 || cornerSelected == 2)
        {
            vertexScaler.x = 0.0f;
        }
    }
    
    if(fabsf(anchorPoint.y) < kTolerance)
    {
        if(cornerSelected == 0 || cornerSelected == 1)
        {
            vertexScaler.y = 0.0f;
        }
    }
    if(fabsf(anchorPoint.y) >  1.0f - kTolerance)
    {
        if(cornerSelected == 2 || cornerSelected == 3)
        {
            vertexScaler.y = 0.0f;
        }
    }
    return vertexScaler;
}

-(CGPoint)projectOntoVertex:(CGPoint)point withContentSize:(CGSize)size alongAxis:(int)axis//b,r,t,l
{
    CGPoint v = CGPointZero;
    CGPoint w = CGPointZero;
    
    switch (axis) {
        case 0:
            w = CGPointMake(size.width, 0.0f);
            break;
        case 1:
            v = CGPointMake(size.width, 0.0f);
            w = CGPointMake(size.width, size.height);
            
            break;
        case 2:
            v = CGPointMake(size.width, size.height);
            w = CGPointMake(0, size.height);
            
            break;
        case 3:
            v = CGPointMake(0, size.height);
            break;
            
        default:
            break;
    }
   
    //see ccpClosestPointOnLine for notes.
    const float l2 =  ccpLengthSQ(ccpSub(w, v));  // i.e. |w-v|^2 -  avoid a sqrt
    const float t = ccpDot(ccpSub(point, v),ccpSub(w , v)) / l2;
    const CGPoint projection =  ccpAdd(v,  ccpMult(ccpSub(w, v),t));  // v + t * (w - v);  Projection falls on the segment
    return projection;

    
}


- (void) mouseDragged:(NSEvent *)event
{
    if (!appDelegate.hasOpenedDocument) return;
    [self mouseMoved:event];

    CGPoint pos = [[CCDirectorMac sharedDirector] convertEventToGL:event];
    
    if ([notesLayer mouseDragged:pos event:event]) return;
    if ([guideLayer mouseDragged:pos event:event]) return;
    if ([appDelegate.physicsHandler mouseDragged:pos event:event]) return;
    
    if (currentMouseTransform == kCCBTransformHandleDownInside)
    {
        CCNode* clickedNode = [nodesAtSelectionPt objectAtIndex:currentNodeAtSelectionPtIdx];
        
        BOOL selectedNodeUnderClickPt = NO;
        for (CCNode* selectedNode in appDelegate.selectedNodes)
        {
            if ([nodesAtSelectionPt containsObject:selectedNode])
            {
                selectedNodeUnderClickPt = YES;
                break;
            }
        }
        
        if ([event modifierFlags] & NSShiftKeyMask)
        {
			[self addNodeToSelection:clickedNode];
        }
        else if (![appDelegate.selectedNodes containsObject:clickedNode]
                 && ! selectedNodeUnderClickPt)
        {
            // Replace selection
            appDelegate.selectedNodes = [NSArray arrayWithObject:clickedNode];
        }
        
        for (CCNode* selectedNode in appDelegate.selectedNodes)
        {
            if(selectedNode.locked)
                continue;
          
            [selectedNode cacheStartTransformAndAnchor];
        }
    
        if (appDelegate.selectedNode != rootNode &&
            ![[[appDelegate.selectedNodes objectAtIndex:0] parent] isKindOfClass:[CCLayout class]]
			//And if its not a joint, or if it is, its draggable.
			&& (!appDelegate.selectedNode.plugIn.isJoint || [(CCBPhysicsJoint*)appDelegate.selectedNode isDraggable]))
        {
            currentMouseTransform = kCCBTransformHandleMove;
        }
    }
    
    if (currentMouseTransform == kCCBTransformHandleMove)
    {
        for (CCNode* selectedNode in appDelegate.selectedNodes)
        {
            if(selectedNode.locked)
                continue;
          
            CGPoint delta = ccp((int)(pos.x - mouseDownPos.x), (int)(pos.y - mouseDownPos.y));
          
            // Handle shift key (straight drags)
            if ([event modifierFlags] & NSShiftKeyMask)
            {
                if (fabs(delta.x) > fabs(delta.y))
                {
                    delta.y = 0;
                }
                else
                {
                    delta.x = 0;
                }
            }
          
            CGAffineTransform startTransform = selectedNode.startTransform;
            CGPoint newAbsPos = ccpAdd(selectedNode.transformStartPosition, delta);
            CGPoint snapDelta = CGPointZero;
            
            // Guide Snap Rules
            if ( ((appDelegate.showGuides && appDelegate.snapToGuides && appDelegate.snapToggle) ||
                 (appDelegate.showGuideGrid && appDelegate.showGuideGrid && appDelegate.snapToggle)) &&
                !([event modifierFlags] & NSCommandKeyMask))
            {
                CGSize size = selectedNode.contentSizeInPoints;

                // Perform snapping (snapping happens in world space)
                CGPoint snapDeltaAP = ccpSub([guideLayer snapPoint:newAbsPos], newAbsPos);
                snapDelta = ccpAdd(snapDelta,snapDeltaAP);
                
                CGPoint cornerBL = ccpAdd(CGPointApplyAffineTransform(ccp(0, 0), startTransform), delta);
                CGPoint snapDeltaBL = ccpSub([guideLayer snapPoint:cornerBL], cornerBL);
                
                // Unique Snaps
                if(snapDelta.x!=snapDeltaBL.x && snapDelta.x==0) {
                    snapDelta = ccpAdd(snapDelta,ccp(snapDeltaBL.x,0));
                }
                if(snapDelta.y!=snapDeltaBL.y && snapDelta.y==0) {
                    snapDelta = ccpAdd(snapDelta,ccp(0,snapDeltaBL.y));
                }
                
                CGPoint cornerBR = ccpAdd(CGPointApplyAffineTransform(ccp(size.width, 0), startTransform), delta);
                CGPoint snapDeltaBR = ccpSub([guideLayer snapPoint:cornerBR], cornerBR);
                if(snapDelta.x!=snapDeltaBR.x && snapDelta.x==0) {
                    snapDelta = ccpAdd(snapDelta,ccp(snapDeltaBR.x,0));
                }
                if(snapDelta.y!=snapDeltaBR.y && snapDelta.y==0) {
                    snapDelta = ccpAdd(snapDelta,ccp(0,snapDeltaBR.y));
                }
                
                CGPoint cornerTL = ccpAdd(CGPointApplyAffineTransform(ccp(0, size.height), startTransform), delta);
                CGPoint snapDeltaTL = ccpSub([guideLayer snapPoint:cornerTL], cornerTL);
                if(snapDelta.x!=snapDeltaTL.x && snapDelta.x==0) {
                    snapDelta = ccpAdd(snapDelta,ccp(snapDeltaTL.x,0));
                }
                if(snapDelta.y!=snapDeltaTL.y && snapDelta.y==0) {
                    snapDelta = ccpAdd(snapDelta,ccp(0,snapDeltaTL.y));
                }
       
                CGPoint cornerTR = ccpAdd(CGPointApplyAffineTransform(ccp(size.width, size.height), startTransform), delta);
                CGPoint snapDeltaTR = ccpSub([guideLayer snapPoint:cornerTR], cornerTR);
                if(snapDelta.x!=snapDeltaTR.x && snapDelta.x==0) {
                    snapDelta = ccpAdd(snapDelta,ccp(snapDeltaTR.x,0));
                }
                if(snapDelta.y!=snapDeltaTR.y && snapDelta.y==0) {
                    snapDelta = ccpAdd(snapDelta,ccp(0,snapDeltaTR.y));
                }
            
            }
            
            newAbsPos = ccpAdd(newAbsPos, snapDelta);
            CGPoint newLocalPos = [selectedNode.parent convertToNodeSpace:newAbsPos];
            
            [appDelegate saveUndoStateWillChangeProperty:@"position"];
            
            selectedNode.position = [selectedNode convertPositionFromPoints:newLocalPos type:selectedNode.positionType];
        }
        [appDelegate refreshProperty:@"position"];
        [snapLayer mouseDragged:pos event:event];
    }
    else if (currentMouseTransform == kCCBTransformHandleScale)
    {
        CGPoint nodePos = [transformScalingNode.parent convertToWorldSpace:transformScalingNode.positionInPoints];
        
        //Where did we start.
        CGPoint deltaStart = ccpSub(nodePos, mouseDownPos);

        //Where are we now.
        CGPoint deltaNew = ccpSub(nodePos, pos);
        
        
        //First, unwind the current mouse down position to form an untransformed 'root' position: ie where on an untransformed image would you have clicked.
        CGSize contentSizeInPoints = transformScalingNode.contentSizeInPoints;
        CGPoint anchorPointInPoints = ccp( contentSizeInPoints.width * transformScalingNode.anchorPoint.x, contentSizeInPoints.height * transformScalingNode.anchorPoint.y );
        
        CGPoint vertexScaler  = {1.0f,1.0f};
        if(transformScalingNode.contentSize.height != 0 && transformScalingNode.contentSize.height != 0)
        {
            vertexScaler = [self vertexLockedScaler:transformScalingNode.anchorPoint withCorner:cornerIndex];
        }
       

        //T
        CGAffineTransform translateTranform = CGAffineTransformTranslate(CGAffineTransformIdentity, -anchorPointInPoints.x, -anchorPointInPoints.y);

        //S
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(transformStartScaleX, transformStartScaleY);
        
        //K
        CGAffineTransform skewTransform = CGAffineTransformMake(1.0f, tanf(CC_DEGREES_TO_RADIANS(transformScalingNode.skewY)),
                                                                tanf(CC_DEGREES_TO_RADIANS(transformScalingNode.skewX)), 1.0f,
                                                                0.0f, 0.0f );
        
        //R
        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(-transformScalingNode.rotation));
        
        //Root position == x,   xTKSR=mouseDown
        //We've got a root position now.
        CGPoint rootPosition = CGPointApplyAffineTransform(deltaStart,CGAffineTransformInvert(CGAffineTransformConcat(CGAffineTransformConcat(CGAffineTransformConcat(translateTranform,skewTransform),scaleTransform), rotationTransform)));
        
        //What scale (S') would be have to adjust to in order to achieve the new mouseDragg position
        //  xTKS'R=mouseDrag,    [xTK]S'=mouseDrag*R^-1
        // [xTK]==known==intermediate==I, R^-1==known, mouseDrag==known, solve so S'
        
        //xTK
        CGPoint intermediate = CGPointApplyAffineTransform(CGPointApplyAffineTransform(rootPosition, translateTranform), skewTransform);
        CGPoint unRotatedMouse = CGPointApplyAffineTransform(deltaNew, CGAffineTransformInvert(rotationTransform));
        
        CGPoint scale = CGPointMake(unRotatedMouse.x/intermediate.x , unRotatedMouse.y / intermediate.y);
        if(isinf(scale.x) || isnan(scale.x))
        {
            scale.x = 0.0;
            vertexScaler.x = 0.0f;
        }

        if(isinf(scale.y) || isnan(scale.y))
        {
            scale.y = 0.0;
            vertexScaler.y = 0.0f;
        }

        
        // Calculate new scale
        float xScaleNew = scale.x * vertexScaler.x + transformStartScaleX * (1.0f - vertexScaler.x);
        float yScaleNew = scale.y * vertexScaler.y + transformStartScaleY * (1.0f - vertexScaler.y);
        
        NodeInfo* nodeInfo = transformScalingNode.userObject;
        
        // Handle shift key (uniform scale)
        if ([event modifierFlags] & NSShiftKeyMask ||  [nodeInfo.extraProps[@"scaleLock"] boolValue])
        {
            // Use the smallest scale composit
            if (fabs(xScaleNew) < fabs(yScaleNew))
            {
                yScaleNew = xScaleNew;
            }
            else
            {
                xScaleNew = yScaleNew;
            }
        }
        
        // Set new scale
        [appDelegate saveUndoStateWillChangeProperty:@"scale"];
        int type = [PositionPropertySetter scaledFloatTypeForNode:transformScalingNode prop:@"scale"];
        [PositionPropertySetter setScaledX:xScaleNew Y:yScaleNew type:type forNode:transformScalingNode prop:@"scale"];
        [appDelegate refreshProperty:@"scale"];
        
        
        //UpdateTheScaleTool
        cornerOrientation = ccpNormalize(deltaNew);
        self.currentTool = kCCBToolScale;//force it to update.

    }
    else if (currentMouseTransform == kCCBTransformHandleRotate)
    {
        CGPoint nodePos = [transformScalingNode.parent convertToWorldSpace:transformScalingNode.positionInPoints];
        
        CGPoint handleAngleVectorStart = ccpSub(nodePos, mouseDownPos);
        CGPoint handleAngleVectorNew = ccpSub(nodePos, pos);
        
        float handleAngleRadStart = atan2f(handleAngleVectorStart.y, handleAngleVectorStart.x);
        float handleAngleRadNew = atan2f(handleAngleVectorNew.y, handleAngleVectorNew.x);
        
        float deltaRotationRad = handleAngleRadNew - handleAngleRadStart;
        float deltaRotation = -(deltaRotationRad/(2*M_PI))*360;
        
        if ([self isLocalCoordinateSystemFlipped:transformScalingNode.parent])
        {
            deltaRotation = -deltaRotation;
        }
        
        while ( deltaRotation > 180.0f )
            deltaRotation -= 360.0f;
        while ( deltaRotation < -180.0f )
            deltaRotation += 360.0f;
        
        float newRotation = (transformStartRotation + deltaRotation);
                // Handle shift key (fixed rotation angles)
        if ([event modifierFlags] & NSShiftKeyMask)
        {
            float factor = 360.0f/16.0f;
            newRotation = roundf(newRotation/factor)*factor;
        }
        
        //Update the rotation tool.
        float cursorRotationRad = -M_PI * (newRotation - transformScalingNode.rotation) / 180.0f;
        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(cursorRotationRad);
        cornerOrientation = CGPointApplyAffineTransform(cornerOrientation, rotationTransform);
        self.currentTool = kCCBToolRotate; //Force it to update.
        
        [appDelegate saveUndoStateWillChangeProperty:@"rotation"];
        transformScalingNode.rotation = newRotation;
        [appDelegate refreshProperty:@"rotation"];
    }
    else if (currentMouseTransform == kCCBTransformHandleSkew)
    {
        CGPoint nodePos = [transformScalingNode.parent convertToWorldSpace:transformScalingNode.positionInPoints];
        CGPoint anchorInPoint = transformScalingNode.anchorPointInPoints;
        
        //Where did we start.
        CGPoint deltaStart = ccpSub(mouseDownPos, nodePos);
        
        //Where are we now.
        CGPoint deltaNew = ccpSub(pos,nodePos);
        
        
        //Delta New needs to be projected onto the vertex we're dragging as we're only effecting one skew at the moment.
       
        //First, unwind the current mouse down position to form an untransformed 'root' position: ie where on an untransformed image would you have clicked.
        //CGSize contentSizeInPoints = transformScalingNode.contentSizeInPoints;
        // CGPoint anchorPointInPoints = ccp( contentSizeInPoints.width * transformScalingNode.anchorPoint.x, contentSizeInPoints.height * transformScalingNode.anchorPoint.y );
        
       
        //T
        CGAffineTransform translateTranform = CGAffineTransformTranslate(CGAffineTransformIdentity, -anchorInPoint.x, -anchorInPoint.y);
        
        //S
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(transformScalingNode.scaleX,transformScalingNode.scaleY);
        
        //K
        CGAffineTransform skewTransform = CGAffineTransformMake(1.0f, tanf(CC_DEGREES_TO_RADIANS(transformStartSkewY)),
                                                                tanf(CC_DEGREES_TO_RADIANS(transformStartSkewX)), 1.0f,
                                                                0.0f, 0.0f );
        
        //R
        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(-transformScalingNode.rotation));
        
        
        CGAffineTransform transform = CGAffineTransformConcat(CGAffineTransformConcat(CGAffineTransformConcat(translateTranform,skewTransform),scaleTransform), rotationTransform);
        
        //Root position == x,   xTKSR=mouseDown
        
        //We've got a root position now.cecream
        CGPoint rootStart = CGPointApplyAffineTransform(deltaStart,CGAffineTransformInvert(transform));
        CGPoint rootNew   = CGPointApplyAffineTransform(deltaNew,CGAffineTransformInvert(transform));
        
        
        //Project the delta mouse position onto
        rootStart   = [self projectOntoVertex:rootStart withContentSize:transformScalingNode.contentSizeInPoints alongAxis:skewSegment];
        rootNew     = [self projectOntoVertex:rootNew   withContentSize:transformScalingNode.contentSizeInPoints alongAxis:skewSegment];
        
        //Apply translation
        rootStart = CGPointApplyAffineTransform(rootStart,translateTranform);
        rootNew   = CGPointApplyAffineTransform(rootNew,translateTranform);
        CGPoint skew = CGPointMake((rootNew.x - rootStart.x)/rootStart.y,(rootNew.y - rootStart.y)/rootStart.x);
        
        CGAffineTransform skewTransform2 = CGAffineTransformMake(1.0f, skew.y,
                                                                skew.x, 1.0f,
                                                                0.0f, 0.0f );
        CGAffineTransform newSkew = CGAffineTransformConcat(skewTransform, skewTransform2);
        
       
        float skewXFinal = CC_RADIANS_TO_DEGREES(atanf(newSkew.c));
        float skewYFinal = CC_RADIANS_TO_DEGREES(atanf(newSkew.b));

        [appDelegate saveUndoStateWillChangeProperty:@"skew"];
        transformScalingNode.skewX = skewXFinal;
        transformScalingNode.skewY = skewYFinal;
        [appDelegate refreshProperty:@"skew"];
        
        
    }
    else if (currentMouseTransform == kCCBTransformHandleAnchorPoint)
    {
        CGPoint localPos = [transformScalingNode convertToNodeSpace:pos];
        CGPoint localDownPos = [transformScalingNode convertToNodeSpace:mouseDownPos];
        
        CGPoint deltaLocal = ccpSub(localPos, localDownPos);
        CGPoint deltaAnchorPoint = ccp(deltaLocal.x / transformScalingNode.contentSizeInPoints.width, deltaLocal.y / transformScalingNode.contentSizeInPoints.height);
        
        [appDelegate saveUndoStateWillChangeProperty:@"anchorPoint"];
        transformScalingNode.anchorPoint = ccpAdd(transformScalingNode.startAnchorPoint, deltaAnchorPoint);
        [appDelegate refreshProperty:@"anchorPoint"];
        
        [self updateAnchorPointCompensation];
    }
    else if (isPanning)
    {
        CGPoint delta = ccpSub(pos, mouseDownPos);
        scrollOffset = ccpAdd(panningStartScrollOffset, delta);
    }
    
    return;
}

- (void) updateAnimateablePropertyValue:(id)value propName:(NSString*)propertyName type:(int)type
{
    snapLinesNeedUpdate = YES;
    CCNode* selectedNode = appDelegate.selectedNode;
    
    NodeInfo* nodeInfo = selectedNode.userObject;
    PlugInNode* plugIn = nodeInfo.plugIn;
    SequencerHandler* sh = [SequencerHandler sharedHandler];
    
    if ([plugIn isAnimatableProperty:propertyName node:selectedNode])
    {
        SequencerSequence* seq = sh.currentSequence;
        int seqId = seq.sequenceId;
        SequencerNodeProperty* seqNodeProp = [selectedNode sequenceNodeProperty:propertyName sequenceId:seqId];
        
        if (seqNodeProp)
        {
            SequencerKeyframe* keyframe = [seqNodeProp keyframeAtTime:seq.timelinePosition];
            if (keyframe)
            {
                keyframe.value = value;
            }
            else
            {
                SequencerKeyframe* keyframe = [[SequencerKeyframe alloc] init];
                keyframe.time = seq.timelinePosition;
                keyframe.value = value;
                keyframe.type = type;
                keyframe.name = seqNodeProp.propName;
                
                [seqNodeProp setKeyframe:keyframe];
                [appDelegate updateInspectorFromSelection];
            }
            
            [sh redrawTimeline];
        }
        else
        {
            [nodeInfo.baseValues setObject:value forKey:propertyName];
        }
    }
}

-(void)addNodeToSelection:(CCNode*)clickedNode
{
	// Add to/subtract from selection
	NSMutableArray* modifiedSelection = [NSMutableArray arrayWithArray: appDelegate.selectedNodes];
	
	if ([modifiedSelection containsObject:clickedNode])
	{
		[modifiedSelection removeObject:clickedNode];
	}
	else
	{
		[modifiedSelection addObject:clickedNode];
	}
	
	
	//If we selected a joint. Only select one joint.
	CCBPhysicsJoint * anyJoint = [modifiedSelection findLast:^BOOL(CCNode * node, int idx) {
		return node.plugIn.isJoint;
	}];
	
	if(anyJoint)
	{
		appDelegate.selectedNodes = @[anyJoint];
	}
	else
	{
		appDelegate.selectedNodes = modifiedSelection;
	}

}

- (void) mouseUp:(NSEvent *)event
{
    if (!appDelegate.hasOpenedDocument) return;
    
    CCNode* selectedNode = appDelegate.selectedNode;
    
    CGPoint pos = [[CCDirectorMac sharedDirector] convertEventToGL:event];
    
    if ([appDelegate.physicsHandler mouseUp:pos event:event]) return;
    
    if (currentMouseTransform == kCCBTransformHandleDownInside)
    {
        CCNode* clickedNode = [nodesAtSelectionPt objectAtIndex:currentNodeAtSelectionPtIdx];
        
        if ([event modifierFlags] & NSShiftKeyMask)
        {
            [self addNodeToSelection:clickedNode];
            
        }
        else
        {
            // Replace selection
            [appDelegate setSelectedNodes:[NSArray arrayWithObject:clickedNode]];
        }
        
        currentMouseTransform = kCCBTransformHandleNone;
    }
    
    if (currentMouseTransform != kCCBTransformHandleNone)
    {
        // Update keyframes & base value
        id value = NULL;
        NSString* propName = NULL;
        int type = kCCBKeyframeTypeDegrees;
        
        if (currentMouseTransform == kCCBTransformHandleRotate)
        {
            value = [NSNumber numberWithFloat: selectedNode.rotation];
            propName = @"rotation";
            type = kCCBKeyframeTypeDegrees;
        }
        else if (currentMouseTransform == kCCBTransformHandleScale)
        {
            float x = [PositionPropertySetter scaleXForNode:selectedNode prop:@"scale"];
            float y = [PositionPropertySetter scaleYForNode:selectedNode prop:@"scale"];
            value = [NSArray arrayWithObjects:
                     [NSNumber numberWithFloat:x],
                     [NSNumber numberWithFloat:y],
                     nil];
            propName = @"scale";
            type = kCCBKeyframeTypeScaleLock;
        }
        else if (currentMouseTransform == kCCBTransformHandleMove)
        {
            CGPoint pt = NSPointToCGPoint([PositionPropertySetter positionForNode:selectedNode prop:@"position"]);
            value = [NSArray arrayWithObjects:
                     [NSNumber numberWithFloat:pt.x],
                     [NSNumber numberWithFloat:pt.y],
                     nil];
            propName = @"position";
            type = kCCBKeyframeTypePosition;
        }
        else if( currentMouseTransform == kCCBTransformHandleSkew)
        {
            float x = [PositionPropertySetter scaleXForNode:selectedNode prop:@"skew"];
            float y = [PositionPropertySetter scaleYForNode:selectedNode prop:@"skew"];
            value = [NSArray arrayWithObjects:
                     [NSNumber numberWithFloat:x],
                     [NSNumber numberWithFloat:y],
                     nil];

            propName = @"skew";
            type = kCCBKeyframeTypeFloatXY;
        }
        
        if (value)
        {
            [self updateAnimateablePropertyValue:value propName:propName type:type];
        }
    }
    
    if ([notesLayer mouseUp:pos event:event]) return;
    if ([guideLayer mouseUp:pos event:event]) return;
    [snapLayer mouseUp:pos event:event];
    
    isMouseTransforming = NO;
    
    if (isPanning)
    {
        self.currentTool = kCCBToolSelection;
        isPanning = NO;
    }
    
    currentMouseTransform = kCCBTransformHandleNone;
    return;
}

- (void)mouseMoved:(NSEvent *)event
{
    if (!appDelegate.hasOpenedDocument) return;
    
    CGPoint pos = [[CCDirectorMac sharedDirector] convertEventToGL:event];
    
    mousePos = pos;
    
    [appDelegate.physicsHandler mouseMove:pos event:event];
    
}

- (void)mouseEntered:(NSEvent *)event
{
    mouseInside = YES;
    
    if (!appDelegate.hasOpenedDocument) return;
    
    [rulerLayer mouseEntered:event];
}
- (void)mouseExited:(NSEvent *)event
{
    mouseInside = NO;
    
    if (!appDelegate.hasOpenedDocument) return;
    
    [rulerLayer mouseExited:event];
}

- (void)cursorUpdate:(NSEvent *)event
{
    if (!appDelegate.hasOpenedDocument) return;
    
}
- (NSImage *)rotateImage:(NSImage *)image rotation:(float)rotation
{
    CGSize imageSize = image.size;
    CGRect rect ={ 0,0, imageSize };
    
    
    NSBitmapImageRep *offscreenRep = [[NSBitmapImageRep alloc]
                                       initWithBitmapDataPlanes:NULL
                                       pixelsWide:imageSize.width
                                       pixelsHigh:imageSize.height
                                       bitsPerSample:8
                                       samplesPerPixel:4
                                       hasAlpha:YES
                                       isPlanar:NO
                                       colorSpaceName:NSDeviceRGBColorSpace
                                       bitmapFormat:NSAlphaFirstBitmapFormat
                                       bytesPerRow:0
                                       bitsPerPixel:0]; ;
    
    NSGraphicsContext * graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep];
    
    CGContextRef context = [graphicsContext graphicsPort];
	if (context)
	{
		CGPoint centerPoint=CGPointMake( imageSize.width/2, imageSize.height/2);
		CGPoint vertex = CGPointMake( -imageSize.width/2, -imageSize.height/2);
		CGAffineTransform tranform = CGAffineTransformMakeRotation(rotation);
		CGPoint vertex2 = CGPointApplyAffineTransform(vertex, tranform);
		CGPoint vertex3 = CGPointMake(centerPoint.x + vertex2.x, centerPoint.y + vertex2.y);
		
		
		CGContextTranslateCTM(context, vertex3.x,vertex3.y);
		CGContextRotateCTM(context, rotation);
		
		CGImageRef maskImage = [image CGImageForProposedRect:nil context:graphicsContext hints:nil];
		CGContextDrawImage(context, rect, maskImage);
	}
	else
	{
		NSLog(@"CocosScene rotateImage: CG draw context is nil");
	}
    
    NSImage*img = [[NSImage alloc] initWithSize:imageSize];;
    [img addRepresentation:offscreenRep];
    return img;
}


-(CCBTool)currentTool
{
    return currentTool;
}

- (void)setCurrentTool:(CCBTool)_currentTool
{
    //First pop any non-selection tools.
    if (currentTool != kCCBToolSelection)
    {
        [NSCursor pop];
    }
    
    currentTool = _currentTool;
    
    if (currentTool == kCCBToolGrab)
    {
        [[NSCursor closedHandCursor] push];
    }
    else if(currentTool == kCCBToolAnchor)
    {
        NSImage * image = [NSImage imageNamed:@"select-crosshair.png"];
        CGPoint centerPoint = CGPointMake(image.size.width/2, image.size.height/2);
        NSCursor * cursor =  [[NSCursor alloc] initWithImage:image hotSpot:centerPoint];
        [cursor push];
    }
    else if (currentTool == kCCBToolRotate)
    {
        NSImage * image = [NSImage imageNamed:@"select-rotation.png"];
        
        float rotation = atan2f(cornerOrientation.y, cornerOrientation.x) - M_PI/4.0f;
        NSImage *img =[self rotateImage:image rotation:rotation];
        CGPoint centerPoint = CGPointMake(img.size.width/2, img.size.height/2);
        NSCursor * cursor =  [[NSCursor alloc] initWithImage:img hotSpot:centerPoint];
        [cursor push];
    }
    else if(currentTool == kCCBToolScale)
    {
        NSImage * image = [NSImage imageNamed:@"select-scale.png"];
        
        float rotation = atan2f(cornerOrientation.y, cornerOrientation.x) + M_PI/2.0f;
        NSImage *img =[self rotateImage:image rotation:rotation];
        CGPoint centerPoint = CGPointMake(img.size.width/2, img.size.height/2);
        NSCursor * cursor =  [[NSCursor alloc] initWithImage:img hotSpot:centerPoint];
        [cursor push];
        
    }
    else if (currentTool == kCCBToolSkew)
    {
        float rotation = atan2f(skewSegmentOrientation.y, skewSegmentOrientation.x);

        //Rotate the Skew image.
        NSImage * image = [NSImage imageNamed:@"select-skew.png"];
        
        NSImage *img =[self rotateImage:image rotation:rotation];

        CGPoint centerPoint = CGPointMake(img.size.width/2, img.size.height/2);

        NSCursor * cursor =  [[NSCursor alloc] initWithImage:img hotSpot:centerPoint];
        [cursor push];
        
    }
    else if(currentTool == kCCBToolTranslate)
    {
        NSImage * image = [NSImage imageNamed:@"select-move.png"];
        CGPoint centerPoint = CGPointMake(image.size.width/2, image.size.height/2);
        NSCursor * cursor =  [[NSCursor alloc] initWithImage:image hotSpot:centerPoint];
        [cursor push];
    }
    
}

- (void) scrollWheel:(NSEvent *)theEvent
{
    snapLinesNeedUpdate = YES; // Disabled in update
    if (!appDelegate.window.isKeyWindow) return;
    if (isMouseTransforming || isPanning || currentMouseTransform != kCCBTransformHandleNone) return;
    if (!appDelegate.hasOpenedDocument) return;
    
    int dx = [theEvent deltaX]*4;
    int dy = -[theEvent deltaY]*4;
    
    scrollOffset.x = scrollOffset.x+dx;
    scrollOffset.y = scrollOffset.y+dy;
}

#pragma mark Post update methods

// This method is called once anytime the selection changes
- (void)selectionUpdated {
    snapLinesNeedUpdate = YES;
}

#pragma mark Updates every frame

- (void) forceRedraw
{
    [self update:0];
    snapLinesNeedUpdate = YES; // Required after the update call to prevent lines from being in random places when switching screen sizes.
}

-(BOOL)hideJoints
{
	if([SequencerHandler sharedHandler].currentSequence.timelinePosition != 0.0f || ![SequencerHandler sharedHandler].currentSequence.autoPlay)
    {
        return YES;
    }
    
    if([AppDelegate appDelegate].playingBack)
    {
        return YES;
    }
	
	if(![AppDelegate appDelegate].showJoints)
	{
		return YES;
	}
	
	return NO;
}


- (void) update:(CCTime)delta
{
    // Recenter the content layer
    BOOL winSizeChanged = !CGSizeEqualToSize(winSize, [[CCDirector sharedDirector] viewSize]);
    winSize = [[CCDirector sharedDirector] viewSize];
    CGPoint stageCenter = ccp((int)(winSize.width/2+scrollOffset.x) , (int)(winSize.height/2+scrollOffset.y));
    
    self.contentSize = winSize;
    
    stageBgLayer.position = stageCenter;
    stageJointsLayer.position = stageCenter;
    renderedScene.position = stageCenter;
    renderedScene.anchorPoint = ccp(0.0f, 0.0f);
    
    if (stageZoom <= 1 || !renderedScene)
    {
        // Use normal rendering
        stageBgLayer.visible = YES;
        renderedScene.visible = NO;
        [borderDevice texture].antialiased = YES;;
    }
    else
    {
        // Render with render-texture
        stageBgLayer.visible = NO;
        renderedScene.visible = YES;
        renderedScene.scale = stageZoom;
        [renderedScene beginWithClear:0 g:0 b:0 a:1];
        [anchorPointCompensationLayer visit];
        [renderedScene end];
        [borderDevice texture].antialiased = NO;
    }
    // Update selection & physics editor
    [selectionLayer removeAllChildrenWithCleanup:YES];
    [physicsLayer removeAllChildrenWithCleanup:YES];
	jointsLayer.visible = ![self hideJoints];
	
    if (appDelegate.physicsHandler.editingPhysicsBody || appDelegate.selectedNode.plugIn.isJoint)
    {
        [appDelegate.physicsHandler updatePhysicsEditor:physicsLayer];
    }
    else
    {
        [self updateSelection];
		[self updateDragging];
    }
    
    // Setup border layer
    CGRect bounds = [stageBgLayer boundingBox];
    
    borderBottom.position = ccp(0,0);
    [borderBottom setContentSize:CGSizeMake(winSize.width, bounds.origin.y)];
    
    borderTop.position = ccp(0, bounds.size.height + bounds.origin.y);
    [borderTop setContentSize:CGSizeMake(winSize.width, winSize.height - bounds.size.height - bounds.origin.y)];
    
    borderLeft.position = ccp(0,bounds.origin.y);
    [borderLeft setContentSize:CGSizeMake(bounds.origin.x, bounds.size.height)];
    
    borderRight.position = ccp(bounds.origin.x+bounds.size.width, bounds.origin.y);
    [borderRight setContentSize:CGSizeMake(winSize.width - bounds.origin.x - bounds.size.width, bounds.size.height)];
    
    CGPoint center = ccp(bounds.origin.x+bounds.size.width/2, bounds.origin.y+bounds.size.height/2);
    borderDevice.position = center;
    
    // Update rulers
    origin = ccpAdd(stageCenter, ccpMult(contentLayer.position,stageZoom));
    origin.x -= stageBgLayer.contentSize.width/2 * stageZoom;
    origin.y -= stageBgLayer.contentSize.height/2 * stageZoom;
    
    [rulerLayer updateWithSize:winSize stageOrigin:origin zoom:stageZoom];
    [rulerLayer updateMousePos:mousePos];
    
    // Update guides
    guideLayer.visible = (appDelegate.showGuides || appDelegate.showGuideGrid) && appDelegate.showExtras;
    [guideLayer updateWithSize:winSize stageOrigin:origin zoom:stageZoom];
    
    // Update sticky notes
    notesLayer.visible = appDelegate.showStickyNotes && appDelegate.showExtras;
    [notesLayer updateWithSize:winSize stageOrigin:origin zoom:stageZoom];
    
    // Update Node Snap
    snapLayer.visible = appDelegate.snapNode && appDelegate.snapToggle;
    [snapLayer updateWithSize:winSize stageOrigin:origin zoom:stageZoom];

    if (winSizeChanged)
    {
        // Update mouse tracking
        if (trackingArea)
        {
            [[appDelegate cocosView] removeTrackingArea:trackingArea];
        }
        
				CGSize sizeInPixels = [[CCDirector sharedDirector] viewSizeInPixels];
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSMakeRect(0, 0, sizeInPixels.width, sizeInPixels.height) options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingActiveInKeyWindow  owner:[appDelegate cocosView] userInfo:NULL];
        [[appDelegate cocosView] addTrackingArea:trackingArea];
    }
    
    [self updateAnchorPointCompensation];
}

- (void) updateAnchorPointCompensation
{
    if (rootNode)
    {
        CGPoint compensation = ccp(rootNode.anchorPoint.x * contentLayer.contentSizeInPoints.width,
                                   rootNode.anchorPoint.y * contentLayer.contentSizeInPoints.height);
        anchorPointCompensationLayer.position = compensation;
    }
}

#pragma mark Document previews

- (void) savePreviewToFile:(NSString*)path
{
    // Remember old position of root node
    CGPoint oldPosition = rootNode.position;
    
    // Create render context
    CCRenderTexture* render = NULL;
    BOOL trimImage = NO;
    if (self.stageSize.width > 0 && self.stageSize.height > 0)
    {
        render = [CCRenderTexture renderTextureWithWidth:self.stageSize.width height:self.stageSize.height];
        rootNode.position = ccp(0,0);
    }
    else
    {
        render = [CCRenderTexture renderTextureWithWidth:2048 height:2048];
        rootNode.position = ccp(1024,1024);
        trimImage = YES;
    }
    
    // Render the root node
    [render beginWithClear:0 g:0 b:0 a:0];
    [anchorPointCompensationLayer visit];
    [render end];
    
    // Reset old position
    rootNode.position = oldPosition;
    
    CGImageRef imgRef = [render newCGImage];
    
    // Trim image if needed
    if (trimImage)
    {
        CGRect trimRect = [Tupac trimmedRectForImage:imgRef];
        CGImageRef trimmedImgRef = CGImageCreateWithImageInRect(imgRef, trimRect);
        CGImageRelease(imgRef);
        imgRef = trimmedImgRef;
    }
    
    // Save preview file
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
	CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
	CGImageDestinationAddImage(dest, imgRef, nil);
	CGImageDestinationFinalize(dest);
	CFRelease(dest);
    
    // Release image
    CGImageRelease(imgRef);

}

#pragma mark Init and dealloc

-(id) initWithAppDelegate:(AppDelegate*)app;
{
    appDelegate = app;
    
    nodesAtSelectionPt = [NSMutableArray array];
    
	if( (self=[super init] ))
    {
        
        [self setupEditorNodes];
        [self setupDefaultNodes];
        
        // self.mouseEnabled = YES;
        self.userInteractionEnabled = YES;
        
        stageZoom = 1;
        
        [self update:0];
	}
	return self;
}

-(void) dealloc
{
	SBLogSelf();
}

#pragma mark Debug


@end
