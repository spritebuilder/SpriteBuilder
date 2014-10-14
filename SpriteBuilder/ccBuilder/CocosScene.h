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

#import "cocos2d.h"
@class SceneGraph;
@class AppDelegate;
@class CCBTemplateNode;
@class RulersLayer;
@class GuidesLayer;
@class NotesLayer;
@class SnapLayer;

enum {
    kCCBParticleTypeExplosion = 0,
    kCCBParticleTypeFire,
    kCCBParticleTypeFireworks,
    kCCBParticleTypeFlower,
    kCCBParticleTypeGalaxy,
    kCCBParticleTypeMeteor,
    kCCBParticleTypeRain,
    kCCBParticleTypeSmoke,
    kCCBParticleTypeSnow,
    kCCBParticleTypeSpiral,
    kCCBParticleTypeSun
};

typedef enum {
    kCCBTransformHandleNone = 0,
    kCCBTransformHandleDownInside,
    kCCBTransformHandleMove,
    kCCBTransformHandleScale,
    kCCBTransformHandleRotate,
    kCCBTransformHandleAnchorPoint,
    kCCBTransformHandleSkew,
} CCBTransformHandle;

typedef enum {
    kCCBToolAnchor      =(1 << 0),
    kCCBToolTranslate   =(1 << 1),
    kCCBToolScale       =(1 << 2),
    kCCBToolGrab        =(1 << 3),
    kCCBToolSkew        =(1 << 4),
    kCCBToolRotate      =(1 << 5),
    kCCBToolSelection   =(1 << 6),
    kCCBToolMax         =(1 << 7)
}CCBTool;

enum {
    kCCBCanvasColorBlack = 0,
    kCCBCanvasColorWhite,
    kCCBCanvasColorGray,
    kCCBCanvasColorOrange,
    kCCBCanvasColorGreen,
};

@interface CocosScene : CCNode
{
    CCNodeColor* bgLayer;
    CCNodeColor* stageBgLayer;
    CCNode     * stageJointsLayer;
    CCNode* anchorPointCompensationLayer;
    CCNode* contentLayer;
    CCNode* selectionLayer;
    CCNode* physicsLayer;
    CCNode* jointsLayer;
    CCNode* borderLayer;
    RulersLayer* rulerLayer;
    GuidesLayer* guideLayer;
    NotesLayer* notesLayer;
    SnapLayer* snapLayer;
    CCNode* rootNode;
    CCRenderTexture* renderedScene;
    AppDelegate* appDelegate;
    CGSize winSize;
    
    NSTrackingArea* trackingArea;
    
    // Mouse handling
    BOOL mouseInside;
    CGPoint mousePos;
    CGPoint mouseDownPos;
    float transformStartRotation;
    float transformStartScaleX;
    float transformStartScaleY;
    CCNode* transformScalingNode;
    float transformStartSkewX;
    float transformStartSkewY;
    
    CCBTransformHandle currentMouseTransform;
    BOOL isMouseTransforming;
    BOOL isPanning;
    BOOL snapLinesNeedUpdate;
    CGPoint scrollOffset;
    CGPoint panningStartScrollOffset;
    
    // Origin position in screen coordinates
    CGPoint origin;
    
    // Selection
    NSMutableArray* nodesAtSelectionPt;
    int currentNodeAtSelectionPtIdx;
    
    CCNodeColor* borderBottom;
    CCNodeColor* borderTop;
    CCNodeColor* borderLeft;
    CCNodeColor* borderRight;
    CCSprite* borderDevice;
    
    int stageBorderType;
    float stageZoom;
    
    CCBTool currentTool;
    CGPoint skewSegmentOrientation;
    int     skewSegment;
    CGPoint cornerOrientation;//which way is the corner facing.
    int     cornerIndex;//Which corner of the object are we rotating?
	
	
	//Dragging and Dropping
	BOOL               effectSpriteDragging;
    CGPoint            effectSpriteDraggingLocation;
}

@property (nonatomic) CCNode* rootNode;

@property (nonatomic,readonly) BOOL isMouseTransforming;
@property (nonatomic,assign) CGPoint scrollOffset;

@property (nonatomic,assign) CCBTool currentTool;

@property (nonatomic,readonly) CCNode* anchorPointCompensationLayer;
@property (nonatomic,readonly) CCNodeColor* bgLayer;
@property (nonatomic,readonly) GuidesLayer* guideLayer;
@property (nonatomic,readonly) RulersLayer* rulerLayer;
@property (nonatomic,readonly) NotesLayer* notesLayer;
@property (nonatomic,readonly) SnapLayer* snapLayer;
@property (nonatomic,readonly) CCNode * physicsLayer;

// Used to creat the scene
+(id) sceneWithAppDelegate:(AppDelegate*)app;

// Used to retrieve the shared instance
+ (CocosScene*) cocosScene;

-(id) initWithAppDelegate:(AppDelegate*)app;

- (void) forceRedraw;

- (void) scrollWheel:(NSEvent *)theEvent;

- (void) setStageSize: (CGSize) size centeredOrigin:(BOOL)centeredOrigin;
- (CGSize) stageSize;
- (BOOL) centeredOrigin;
- (void) setStageBorder:(int)type;
- (int) stageBorder;
- (void) setStageColor: (int) type forDocDimensionsType: (int) docDimensionsType;

- (void) setStageZoom:(float) zoom;
- (float) stageZoom;

- (void) replaceSceneNodes:(SceneGraph*)sceneGraph;

- (void) updateSelection;
- (void) selectBehind;

- (void) selectionUpdated;

// Event handling forwarded by view
- (void)mouseMoved:(NSEvent *)event;
- (void)mouseEntered:(NSEvent *)event;
- (void)mouseExited:(NSEvent *)event;
- (void)cursorUpdate:(NSEvent *)event;

//Draggin
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender pos:(CGPoint)pos;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender pos:(CGPoint)pos;
- (void)draggingExited:(id <NSDraggingInfo>)sender pos:(CGPoint)pos;
- (void)draggingEnded:(id <NSDraggingInfo>)sender;
- (CCNode*)findObjectAtPoint:(CGPoint)point ofTypes:(NSArray*)filterClassTypes;


- (void) savePreviewToFile:(NSString*)path;

// Converts to document coordinates from view coordinates
- (CGPoint) convertToDocSpace:(CGPoint)viewPt;
// Converst to view coordinates from document coordinates
- (CGPoint) convertToViewSpace:(CGPoint)docPt;

@end