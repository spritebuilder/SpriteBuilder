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
#import "CCEffect.h"

@implementation CCBGLView

- (void) reshape
{
    [self removeTrackingRect:trackingTag];
    trackingTag = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
    [[AppDelegate appDelegate] resizeGUIWindow:[self bounds].size];
    
    [super reshape];
}

- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    trackingTag = [self addTrackingRect:[self bounds] owner:self userData:NULL assumeInside:NO];
    
    [self registerForDraggedTypes:[NSArray arrayWithObjects: @"com.cocosbuilder.texture", @"com.cocosbuilder.template", @"com.cocosbuilder.ccb", @"com.cocosbuilder.PlugInNode", @"com.cocosbuilder.jointBody", @"com.cocosbuilder.effectSprite", NULL]];
}


-(BOOL) acceptsFirstResponder
{
	return NO;
}

#pragma mark Dragging

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
    NSPoint pt = [self convertPoint:[sender draggingLocation] fromView:NULL];
    pt = NSMakePoint(roundf(pt.x),roundf(pt.y));
    pt = [[CCDirectorMac sharedDirector] convertToGL:pt];

    
    return [[CocosScene cocosScene] draggingEntered:sender pos:pt];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    NSPoint pt = [self convertPoint:[sender draggingLocation] fromView:NULL];
    pt = NSMakePoint(roundf(pt.x),roundf(pt.y));
    pt = [[CCDirectorMac sharedDirector] convertToGL:pt];
    
    return [[CocosScene cocosScene] draggingUpdated:sender pos:pt];
    
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    NSPoint pt = [self convertPoint:[sender draggingLocation] fromView:NULL];
    pt = NSMakePoint(roundf(pt.x),roundf(pt.y));
    pt = [[CCDirectorMac sharedDirector] convertToGL:pt];
    
    [[CocosScene cocosScene] draggingExited:sender pos:pt];
    
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
    NSPoint pt = [self convertPoint:[sender draggingLocation] fromView:NULL];
    pt = NSMakePoint(roundf(pt.x),roundf(pt.y));
    pt = [[CCDirectorMac sharedDirector] convertToGL:pt];
    
    NSPasteboard* pb = [sender draggingPasteboard];
    
    // Textures
    NSArray* pbTextures = [pb propertyListsForType:@"com.cocosbuilder.texture"];
    for (NSDictionary* dict in pbTextures)
    {
        [appDelegate dropAddSpriteNamed:[dict objectForKey:@"spriteFile"] inSpriteSheet:[dict objectForKey:@"spriteSheetFile"] at:ccp(pt.x,pt.y)];
    }
    
    // CCB Files
    NSArray* pbCCBs = [pb propertyListsForType:@"com.cocosbuilder.ccb"];
    for (NSDictionary* dict in pbCCBs)
    {
        [appDelegate dropAddCCBFileNamed:[dict objectForKey:@"ccbFile"] at:ccp(pt.x,pt.y) parent:NULL];
    }
    
    // PlugInNode
    NSArray* pbPlugInNode = [pb propertyListsForType:@"com.cocosbuilder.PlugInNode"];
    for (NSDictionary* dict in pbPlugInNode)
    {
        [appDelegate dropAddPlugInNodeNamed:[dict objectForKey:@"nodeClassName"] at:ccp(pt.x, pt.y)];
    }
    
    NSArray* pbJoints = [pb propertyListsForType:@"com.cocosbuilder.jointBody"];
    for (NSDictionary* dict in pbJoints)
    {
        
        CGPoint point = ccp(pt.x, pt.y);
        
        CCNode * body = [appDelegate.physicsHandler findPhysicsBodyAtPoint:point];
        if(!body)
            return NO;
        
        NSUInteger uuid = [dict[@"uuid"] unsignedIntegerValue];
        JointHandleType type = [dict[@"bodyIndex"] integerValue];
        
        CCBPhysicsJoint * joint = [[SceneGraph instance].joints.all findFirst:^BOOL(CCBPhysicsJoint * lJoint, int idx) {
            return lJoint.UUID == uuid;
        }];
        
        [appDelegate.physicsHandler assignBodyToJoint:body toJoint:joint withIdx:type pos:point];
        
    }
	
	NSArray* pbSprites = [pb propertyListsForType:@"com.cocosbuilder.effectSprite"];
    for (NSDictionary* dict in pbSprites)
    {

        CGPoint point = ccp(pt.x, pt.y);
		
		NSArray * classTypes = @[NSStringFromClass([CCSprite class])];
		
		CCNode * node = [[CocosScene cocosScene] findObjectAtPoint:point ofTypes:classTypes];
        		  
        if(!node)
            return NO;
	
		NSUInteger effectUUID = [dict[@"effect"] unsignedIntegerValue];
		
		CCEffect<EffectProtocol>*effect = [[SceneGraph instance].rootNode findEffect:effectUUID];
		if(!effect)
		{
			NSLog(@"Failed to find effect instance in scene graph.");
			return NO;
		}
		
		NSString* propertyName = dict[@"propertyName"];
		
		[effect setValue:node forKey:propertyName];
		[[AppDelegate appDelegate] refreshProperty:@"effects"];
	}


    return YES;
}

#pragma mark -

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
            [cs setStageZoom:[cs stageZoom] + [event magnification]];
        }
    }
    else if ([event magnification] < 0)
    {
        if ([cs stageZoom] + [event magnification] > 0.25)
        {
            [cs setStageZoom:[cs stageZoom] + [event magnification]];
        }
        else
        {
            [cs setStageZoom:0.25];
        }
    }
}

-(void) dealloc
{
	SBLogSelf();
}

@end
