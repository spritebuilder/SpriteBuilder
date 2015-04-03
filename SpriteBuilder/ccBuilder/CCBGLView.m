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

#import "CCBGLView.h"
#import "AppDelegate.h"
#import "CCBGlobals.h"
#import "CocosScene.h"
#import "NSPasteboard+CCB.h"
#import "PhysicsHandler.h"
#import "SceneGraph.h"
#import "NSArray+Query.h"
#import "CCNode+NodeInfo.h"
#import "EffectsManager.h"
#import "InspectorController.h"
#import "CCEffect.h"
#import "PasteboardTypes.h"
#import "InspectorController.h"

@implementation CCBGLView

- (void)awakeFromNib
{
    [super awakeFromNib];

    trackingTag = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];

    [self registerForDraggedTypes:@[
            PASTEBOARD_TYPE_TEXTURE,
            PASTEBOARD_TYPE_TEMPLATE,
            PASTEBOARD_TYPE_SB,
            PASTEBOARD_TYPE_PLUGINNODE,
            PASTEBOARD_TYPE_JOINTBODY,
            PASTEBOARD_TYPE_EFFECTSPRITE]];
}

- (void)reshape
{
    [self removeTrackingRect:trackingTag];
    trackingTag = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
    [[AppDelegate appDelegate] resizeGUIWindow:[self bounds].size];

    [super reshape];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return NO;
}


#pragma mark Dragging

- (NSPoint)convertDragginLocationToLocalPoint:(NSPoint)draggingLocation
{
    NSPoint point = [self convertPoint:draggingLocation fromView:NULL];
    point = NSMakePoint(roundf((float) point.x),roundf((float) point.y));
    return [[CCDirectorMac sharedDirector] convertToGL:point];
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
    NSPoint localDragPoint = [self convertDragginLocationToLocalPoint:[sender draggingLocation]];

    return [[CocosScene cocosScene] draggingEntered:sender pos:localDragPoint];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    NSPoint localDragPoint = [self convertDragginLocationToLocalPoint:[sender draggingLocation]];

    return [[CocosScene cocosScene] draggingUpdated:sender pos:localDragPoint];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    NSPoint localDragPoint = [self convertDragginLocationToLocalPoint:[sender draggingLocation]];

    [[CocosScene cocosScene] draggingExited:sender pos:localDragPoint];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    
}

/* draggingEnded: is implemented as of Mac OS 10.5 */
- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    [[CocosScene cocosScene] draggingEnded:sender];
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
    NSPoint localDragPoint = [self convertDragginLocationToLocalPoint:[sender draggingLocation]];
    NSPasteboard* pasteboard = [sender draggingPasteboard];

    [self performDragForTexture:localDragPoint pasteboard:pasteboard];

    [self performDragForCCB:localDragPoint pasteboard:pasteboard];

    [self performDragForPluginNode:localDragPoint pasteboard:pasteboard];

    if (![self performDragForPhysicsJointBody:localDragPoint pasteboard:pasteboard])
    {
        return NO;
    }

    if (![self performDragForEffect:localDragPoint pasteboard:pasteboard])
    {
        return NO;
    }

    return YES;
}

- (BOOL)performDragForPhysicsJointBody:(NSPoint)dragPoint pasteboard:(NSPasteboard *)pasteboard
{
    NSArray* pbJoints = [pasteboard propertyListsForType:PASTEBOARD_TYPE_JOINTBODY];
    for (NSDictionary* dict in pbJoints)
    {
        CGPoint point = ccp(dragPoint.x, dragPoint.y);
        CCNode * body = [self->appDelegate.physicsHandler findPhysicsBodyAtPoint:point];

        if (!body)
        {
            return NO;
        }

        NSUInteger uuid = [dict[@"uuid"] unsignedIntegerValue];
        JointHandleType type = (JointHandleType) [dict[@"bodyIndex"] integerValue];

        CCBPhysicsJoint * joint = [[SceneGraph instance].joints.all findFirst:^BOOL(CCBPhysicsJoint * lJoint, int idx) {
            return lJoint.UUID == uuid;
        }];

        [self->appDelegate.physicsHandler assignBodyToJoint:body toJoint:joint withIdx:type pos:point];
    }
    return YES;
}

- (void)performDragForPluginNode:(NSPoint)dragPoint pasteboard:(NSPasteboard *)pasteboard
{
    NSArray* pbPlugInNode = [pasteboard propertyListsForType:PASTEBOARD_TYPE_PLUGINNODE];
    for (NSDictionary* dict in pbPlugInNode)
    {
        [appDelegate dropAddPlugInNodeNamed:dict[@"nodeClassName"] at:ccp(dragPoint.x, dragPoint.y)];
    }
}

- (void)performDragForCCB:(NSPoint)dragPoint pasteboard:(NSPasteboard *)pasteboard
{
    NSArray* pbCCBs = [pasteboard propertyListsForType:PASTEBOARD_TYPE_SB];
    for (NSDictionary* dict in pbCCBs)
    {
        [appDelegate dropAddCCBFileNamed:dict[@"ccbFile"] at:ccp(dragPoint.x, dragPoint.y) parent:NULL];
    }
}

- (void)performDragForTexture:(NSPoint)dragPoint pasteboard:(NSPasteboard *)pasteboard
{
    NSArray* pbTextures = [pasteboard propertyListsForType:PASTEBOARD_TYPE_TEXTURE];
    for (NSDictionary* dict in pbTextures)
    {
        [appDelegate dropAddSpriteNamed:dict[@"spriteFile"]
                          inSpriteSheet:dict[@"spriteSheetFile"]
                                     at:ccp(dragPoint.x, dragPoint.y)];
    }
}

- (BOOL)performDragForEffect:(NSPoint)point pasteboard:(NSPasteboard *)pasteboard
{
    NSArray* pbSprites = [pasteboard propertyListsForType:PASTEBOARD_TYPE_EFFECTSPRITE];
    for (NSDictionary* dict in pbSprites)
    {
        CGPoint aPoint = ccp(point.x, point.y);
        NSArray *classTypes = @[NSStringFromClass([CCSprite class])];
        CCNode *node = [[CocosScene cocosScene] findObjectAtPoint:aPoint ofTypes:classTypes];

        if (!node)
        {
            return NO;
        }

        NSUInteger effectUUID = [dict[@"effect"] unsignedIntegerValue];

        CCEffect <EffectProtocol> *effect = [[SceneGraph instance].rootNode findEffect:effectUUID];
        if (!effect)
        {
            NSLog(@"Failed to find effect instance in scene graph.");
            return NO;
        }

        NSString *propertyName = dict[@"propertyName"];

        [effect setValue:node forKey:propertyName];
        [_inspectorController refreshProperty:@"effects"];
	}

    return YES;
}


#pragma mark - Mouse Events

- (void) scrollWheel:(NSEvent *)theEvent
{
    [[CocosScene cocosScene] scrollWheel:theEvent];
}

- (void)mouseMoved:(NSEvent *)event
{
    [[CocosScene cocosScene] mouseMoved:event];
}

- (void)mouseEntered:(NSEvent *)event
{
    [[CocosScene cocosScene] mouseEntered:event];
}

- (void)mouseExited:(NSEvent *)event
{
    [[CocosScene cocosScene] mouseExited:event];
}

- (void)cursorUpdate:(NSEvent *)event
{
    [[CocosScene cocosScene] cursorUpdate:event];
}

#pragma mark Trackpad Events

- (void)magnifyWithEvent:(NSEvent *)event
{
    CocosScene* cs = [CocosScene cocosScene];
    
    if ([event magnification] > 0)
    {
        if ([cs stageZoom] < 1.5f)
        {
            [cs setStageZoom:(float) ([cs stageZoom] + [event magnification])];
        }
    }
    else if ([event magnification] < 0)
    {
        if ([cs stageZoom] + [event magnification] > 0.25)
        {
            [cs setStageZoom:(float) ([cs stageZoom] + [event magnification])];
        }
        else
        {
            [cs setStageZoom:0.25];
        }
    }
}

@end
