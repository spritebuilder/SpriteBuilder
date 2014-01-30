/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
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

#import "PositionPropertySetter.h"
#import "CCBGlobals.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "AppDelegate.h"
#import "CCBDocument.h"
#import "ResolutionSetting.h"
#import "NodeGraphPropertySetter.h"
#import "CCNode+NodeInfo.h"
#import "SequencerHandler.h"
#import "SequencerSequence.h"
#import "SequencerNodeProperty.h"
#import "SequencerKeyframe.h"

@implementation PositionPropertySetter

+ (CGSize) getParentSize:(CCNode*) node
{
    CocosScene* cs = [CocosScene cocosScene];
    
    // Get parent size
    CGSize parentSize;
    if (cs.rootNode == node)
    {
        // This is the document root node
        parentSize = cs.stageSize;
    }
    else if (node.parent)
    {
        // This node has a parent
        parentSize = node.parent.contentSize;
    }
    else
    {
        // This is a node loaded from a sub-ccb file (or the node graph isn't loaded yet)
        NSLog(@"No parent!!!");
    }
    return parentSize;
}

/*
+ (void) refreshPositionsForChildren:(CCNode*)node
{
    NodeInfo* info = node.userObject;
    PlugInNode* plugIn = info.plugIn;
    if (!plugIn.canHaveChildren) return;
    
    NSArray* children = [node children];
    for (int i = 0; i < [children count]; i++)
    {
        CCNode* child = [children objectAtIndex:i];
        NodeInfo* info = child.userObject;
        PlugInNode* plugIn = info.plugIn;
        
        NSArray* positionProps = [plugIn readablePropertiesForType:@"Position" node:node];
        for (NSString* prop in positionProps)
        {
            NSPoint oldPos = [PositionPropertySetter positionForNode:child prop:prop];
            [PositionPropertySetter setPosition:oldPos forNode:child prop:prop];
        }
        
        NSArray* sizeProps = [plugIn readablePropertiesForType:@"Size" node:node];
        for (NSString* prop in sizeProps)
        {
            NSSize oldSize = [PositionPropertySetter sizeForNode:child prop:prop];
            [PositionPropertySetter setSize:oldSize forNode:child prop:prop];
        }
        
        NSArray* ccbFileProps = [plugIn readablePropertiesForType:@"CCBFile" node:node];
        for (NSString* prop in ccbFileProps)
        {
            CCNode* ccbFileNode = [child valueForKey:prop];
            [PositionPropertySetter refreshPositionsForChildren:ccbFileNode];
            //NSLog(@"refreshPositionFor CCBFile: %@",ccbFileNode);
            // Reload ccbFiles
            //NSString* ccbFile = [NodeGraphPropertySetter nodeGraphNameForNode:child andProperty:prop];
            //[NodeGraphPropertySetter setNodeGraphForNode:child andProperty:prop withFile:ccbFile parentSize:node.contentSize];
        }
    }
}

+ (void) refreshAllPositions
{
    CocosScene* cs = [CocosScene cocosScene];
    
    // Update root position
    [PositionPropertySetter setPosition:[PositionPropertySetter positionForNode:cs.rootNode prop:@"position"] forNode:cs.rootNode prop:@"position"];
    
    // Update root's children
    NSSize rootNodeSize = [PositionPropertySetter sizeForNode:cs.rootNode prop:@"contentSize"];
    [PositionPropertySetter setSize:rootNodeSize forNode:cs.rootNode prop:@"contentSize"];
}
*/
 
/*
+ (NSPoint) calcAbsolutePositionFromRelative:(NSPoint)pos type:(int)type parentSize:(CGSize) parentSize
{
    // Get parent size
    //CGSize parentSize = [PositionPropertySetter getParentSize:node];
    
    // Calculate absolute position
    NSPoint absPos = NSZeroPoint;
    
    if (type == kCCBPositionTypePercent)
    {
        absPos.x = roundf(pos.x * parentSize.width * 0.01f);
        absPos.y = roundf(pos.y * parentSize.height * 0.01f);
    }
    else if (type == kCCBPositionTypeRelativeBottomLeft)
    {
        absPos = pos;
    }
    else if (type == kCCBPositionTypeRelativeTopLeft)
    {
        absPos.x = pos.x;
        absPos.y = parentSize.height - pos.y;
    }
    else if (type == kCCBPositionTypeRelativeTopRight)
    {
        absPos.x = parentSize.width - pos.x;
        absPos.y = parentSize.height - pos.y;
    }
    else if (type == kCCBPositionTypeRelativeBottomRight)
    {
        absPos.x = parentSize.width - pos.x;
        absPos.y = pos.y;
    }
    else if (type == kCCBPositionTypeMultiplyResolution)
    {
        AppDelegate* ad = [AppDelegate appDelegate];
        int currentResolution = ad.currentDocument.currentResolution;
        ResolutionSetting* resolution = [ad.currentDocument.resolutions objectAtIndex:currentResolution];
        
        absPos.x = pos.x * resolution.scale;
        absPos.y = pos.y * resolution.scale;
    }
    
    return absPos;
}*/

/*
+ (NSPoint) calcRelativePositionFromAbsolute:(NSPoint)pos type:(int)type parentSize:(CGSize)parentSize
{
    // Get parent size
    //CGSize parentSize = [PositionPropertySetter getParentSize:node];
    
    NSPoint relPos = NSZeroPoint;
    
    if (type == kCCBPositionTypePercent)
    {
        if (parentSize.width > 0)
        {
            relPos.x = pos.x/parentSize.width*100.0f;
        }
        else
        {
            relPos.x = 0;
        }
        
        if (parentSize.height > 0)
        {
            relPos.y = pos.y/parentSize.height*100.0f;
        }
        else
        {
            relPos.y = 0;
        }
    }
    else if (type == kCCBPositionTypeRelativeBottomLeft)
    {
        relPos = pos;
    }
    else if (type == kCCBPositionTypeRelativeTopLeft)
    {
        relPos.x = pos.x;
        relPos.y = parentSize.height - pos.y;
    }
    else if (type == kCCBPositionTypeRelativeTopRight)
    {
        relPos.x = parentSize.width - pos.x;
        relPos.y = parentSize.height - pos.y;
    }
    else if (type == kCCBPositionTypeRelativeBottomRight)
    {
        relPos.x = parentSize.width - pos.x;
        relPos.y = pos.y;
    }
    else if (type == kCCBPositionTypeMultiplyResolution)
    {
        AppDelegate* ad = [AppDelegate appDelegate];
        int currentResolution = ad.currentDocument.currentResolution;
        ResolutionSetting* resolution = [ad.currentDocument.resolutions objectAtIndex:currentResolution];
        
        relPos.x = pos.x / resolution.scale;
        relPos.y = pos.y / resolution.scale;
    }
    
    return relPos;
}*/


+ (void) setPosition:(NSPoint)pos type:(CCPositionType)type forNode:(CCNode*) node prop:(NSString*)prop
{
    // Set the position type
    NSValue* typeValue = [NSValue value:&type withObjCType:@encode(CCPositionType)];
    [node setValue:typeValue forKey:[prop stringByAppendingString:@"Type"]];
    
    // Set position
    [node setValue:[NSValue valueWithPoint:pos] forKey:prop];
    
    //[PositionPropertySetter setPosition:pos type:type forNode:node prop:prop parentSize:[PositionPropertySetter getParentSize:node]];
}

/*
+ (void) setPosition:(NSPoint)pos type:(int)type forNode:(CCNode*) node prop:(NSString*)prop parentSize:(CGSize)parentSize
{
    NSPoint absPos = [PositionPropertySetter calcAbsolutePositionFromRelative:pos type:type parentSize:parentSize];
    
    // Set the position value
    [node setValue:[NSValue valueWithPoint:absPos] forKey:prop];
    
    // Set the extra properties
    [node setExtraProp:[NSValue valueWithPoint:pos] forKey:prop];
    [node setExtraProp:[NSNumber numberWithInt:type] forKey:[NSString stringWithFormat:@"%@Type", prop]];
}*/

+ (void) addPositionKeyframeForNode:(CCNode*)node
{
    NSPoint newPos = [PositionPropertySetter positionForNode:node prop:@"position"];
    
    // Update animated value
    NSArray* animValue = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:newPos.x],
                          [NSNumber numberWithFloat:newPos.y],
                          NULL];
    
    NodeInfo* nodeInfo = node.userObject;
    PlugInNode* plugIn = nodeInfo.plugIn;
    
    if ([plugIn isAnimatableProperty:@"position" node:node])
    {
        SequencerSequence* seq = [SequencerHandler sharedHandler].currentSequence;
        int seqId = seq.sequenceId;
        SequencerNodeProperty* seqNodeProp = [node sequenceNodeProperty:@"position" sequenceId:seqId];
        
        if (seqNodeProp)
        {
            SequencerKeyframe* keyframe = [seqNodeProp keyframeAtTime:seq.timelinePosition];
            if (keyframe)
            {
                keyframe.value = animValue;
            }
            
            [[SequencerHandler sharedHandler] redrawTimeline];
        }
        else
        {
            [nodeInfo.baseValues setObject:animValue forKey:@"position"];
        }
    }
}

+ (void) setPosition:(NSPoint)pos forNode:(CCNode *)node prop:(NSString *)prop
{
    //int type = [PositionPropertySetter positionTypeForNode:node prop:prop];
    //[PositionPropertySetter setPosition:pos type:type forNode:node prop:prop];
    [node setValue:[NSValue valueWithPoint:pos] forKey:prop];
}

+ (void) setPositionType:(CCPositionType)type forNode:(CCNode*)node prop:(NSString*)prop
{
    // Get position in points
    CGPoint absPos = NSPointToCGPoint([[node valueForKey:[prop stringByAppendingString:@"InPoints"]] pointValue]);
    
    // Set the position type
    NSValue* typeValue = [NSValue value:&type withObjCType:@encode(CCPositionType)];
    [node setValue:typeValue forKey:[prop stringByAppendingString:@"Type"]];
    
    // Calculate new position (from old value)
    CGPoint relPos = [node convertPositionFromPoints:absPos type:type];
    
    // Update the position
    NSValue* pointValue = [NSValue valueWithPoint: NSPointFromCGPoint(relPos)];
    [node setValue:pointValue forKey:prop];
    
    //NSPoint oldAbsPos = [[node valueForKey:prop] pointValue];
    //NSPoint relPos = [PositionPropertySetter calcRelativePositionFromAbsolute:oldAbsPos type:type parentSize:[PositionPropertySetter getParentSize:node]];
    //[PositionPropertySetter setPosition:relPos type:type forNode:node prop:prop];
}

+ (NSPoint) positionForNode:(CCNode*)node prop:(NSString*)prop
{
    return [[node valueForKey:prop] pointValue];
}

+ (CCPositionType) positionTypeForNode:(CCNode*)node prop:(NSString*)prop
{
    NSValue* typeValue = [node valueForKey:[prop stringByAppendingString:@"Type"]];
    CCPositionType type;
    [typeValue getValue:&type];
    
    return type;
    //return [[node extraPropForKey:[NSString stringWithFormat:@"%@Type", prop]] intValue];
}

+ (NSPoint) convertPosition:(NSPoint)pos fromType:(CCPositionType)fromType toType:(CCPositionType)toType forNode:(CCNode*) node
{
    // Ignore non conversions
    if (fromType.xUnit == toType.xUnit && fromType.yUnit == toType.yUnit && fromType.corner == toType.corner) return pos;
    
    // Save old type
    CCPositionType oldType = node.positionType;
    
    // Do the conversion
    node.positionType = fromType;
    CGPoint absPos = [node convertPositionToPoints:pos type:node.positionType];
    node.positionType = toType;
    CGPoint newPos = [node convertPositionFromPoints:absPos type:node.positionType];
    
    // Restore old type
    node.positionType = oldType;
    
    // Return converted value
    return newPos;
}

+ (void) setSize:(NSSize)size type:(CCSizeType)type forNode:(CCNode*)node prop:(NSString*)prop
{
    // Set type
    NSValue* typeValue = [NSValue value:&type withObjCType:@encode(CCSizeType)];
    [node setValue:typeValue forKey:[prop stringByAppendingString:@"Type"]];
    
    // Set size
    [node setValue:[NSValue valueWithSize:size] forKey:prop];
}

+ (void) setSizeType:(CCSizeType)type forNode:(CCNode*)node prop:(NSString*)prop
{
    // Figure out which properties to update
    PlugInNode* plugIn = node.plugIn;
    NSDictionary* properties = plugIn.nodePropertiesDict;
    
    NSArray* affectedProps = [[properties objectForKey:prop] objectForKey:@"affectsProperties"];
    NSMutableArray* propsToUpdate = [affectedProps mutableCopy];
    if (!propsToUpdate) propsToUpdate = [NSMutableArray array];
    
    for (int i = propsToUpdate.count -1; i >= 0; i--)
    {
        NSString* canditate = [propsToUpdate objectAtIndex:i];
        BOOL removeCandidate = NO;
        
        // Remove candidates that are read only
        if ([[[properties objectForKey:canditate] objectForKey:@"readOnly"] boolValue])
        {
            removeCandidate = YES;
        }
        
        // Remove candidates that are not size type
        if (![[[properties objectForKey:canditate] objectForKey:@"type"] isEqualToString:@"Size"])
        {
            removeCandidate = YES;
        }
        
        if (removeCandidate) [propsToUpdate removeObjectAtIndex:i];
    }
    
    // Always update this property
    [propsToUpdate addObject:prop];

    // Update the values
    NSMutableArray* absSizes = [NSMutableArray array];
    
    for (NSString* prop in propsToUpdate)
    {
        // Get absolute size
        CGSize oldSize = [PositionPropertySetter sizeForNode:node prop:prop];
        CGSize absSize = [node convertContentSizeToPoints:oldSize type:node.contentSizeType];
        
        [absSizes addObject:[NSValue valueWithSize:absSize]];
    }
    
    // Change the type
    NSValue* typeValue = [NSValue value:&type withObjCType:@encode(CCSizeType)];
    [node setValue:typeValue forKey:[prop stringByAppendingString:@"Type"]];
    
    int i = 0;
    for (NSString* prop in propsToUpdate)
    {
        // Calculate relative size for new type
        CGSize absSize = [[absSizes objectAtIndex:i] sizeValue];
        CGSize newSize = [node convertContentSizeFromPoints:absSize type:node.contentSizeType];
        
        [node setValue:[NSValue valueWithSize:newSize] forKey:prop];
        i++;
    }
}

+ (void) setSize:(NSSize)size forNode:(CCNode *)node prop:(NSString *)prop
{
    [node setValue:[NSValue valueWithSize:size] forKey:prop];
}

+ (NSSize) sizeForNode:(CCNode*)node prop:(NSString*)prop
{
    return [[node valueForKey:prop] sizeValue];
}

+ (CCSizeType) sizeTypeForNode:(CCNode*)node prop:(NSString*)prop
{
    NSValue* sizeValue = [node valueForKey:[prop stringByAppendingString:@"Type"]];
    CCSizeType type;
    [sizeValue getValue:&type];
    
    return type;
}

/*
+ (void) refreshSizeForNode:(CCNode*)node prop:(NSString*)prop
{
    int type = [PositionPropertySetter sizeTypeForNode:node prop:prop];
    if (type == kCCBSizeTypeAbsolute)
    {
        NSSize size = [[node valueForKey:prop] sizeValue];
        [PositionPropertySetter setSize:size forNode:node prop:prop];
    }
}*/

+ (void) setScaledX:(float)scaleX Y:(float)scaleY type:(int)type forNode:(CCNode*)node prop:(NSString*)prop
{
    AppDelegate* ad = [AppDelegate appDelegate];
    int currentResolution = ad.currentDocument.currentResolution;
    ResolutionSetting* resolution = [ad.currentDocument.resolutions objectAtIndex:currentResolution];
    
    float absScaleX = 0;
    float absScaleY = 0;
    if (type == kCCBScaleTypeAbsolute)
    {
        absScaleX = scaleX;
        absScaleY = scaleY;
    }
    else if (type == kCCBScaleTypeMultiplyResolution)
    {
        absScaleX = scaleX / resolution.scale;
        absScaleY = scaleY / resolution.scale;
    }
    
    [node setValue:[NSNumber numberWithFloat:absScaleX] forKey:[prop stringByAppendingString:@"X"]];
    [node setValue:[NSNumber numberWithFloat:absScaleY] forKey:[prop stringByAppendingString:@"Y"]];
    
    [node setExtraProp:[NSNumber numberWithFloat:scaleX] forKey:[prop stringByAppendingString:@"X"]];
    [node setExtraProp:[NSNumber numberWithFloat:scaleY] forKey:[prop stringByAppendingString:@"Y"]];
    [node setExtraProp:[NSNumber numberWithInt:type] forKey:[NSString stringWithFormat:@"%@Type", prop]];
}

+ (float) scaleXForNode:(CCNode*)node prop:(NSString*)prop
{
    NSNumber* scale = [node extraPropForKey:[prop stringByAppendingString:@"X"]];
    if(!scale)
        scale = [node valueForKey:[prop stringByAppendingString:@"X"]];
        
    if (!scale)
        return 1;
    
    return [scale floatValue];
}

+ (float) scaleYForNode:(CCNode*)node prop:(NSString*)prop
{
    NSNumber* scale = [node extraPropForKey:[prop stringByAppendingString:@"Y"]];
    
    if(!scale)
        scale = [node valueForKey:[prop stringByAppendingString:@"Y"]];

    if (!scale)
        return 1;
    return [scale floatValue];
}

+ (int) scaledFloatTypeForNode:(CCNode*)node prop:(NSString*)prop
{
    return [[node extraPropForKey:[NSString stringWithFormat:@"%@Type", prop]] intValue];
}

+ (void) setFloatScale:(float)f type:(int)type forNode:(CCNode*)node prop:(NSString*)prop
{
    AppDelegate* ad = [AppDelegate appDelegate];
    int currentResolution = ad.currentDocument.currentResolution;
    ResolutionSetting* resolution = [ad.currentDocument.resolutions objectAtIndex:currentResolution];
    
    float absF = f;
    if (type == kCCBScaleTypeMultiplyResolution)
    {
        absF = f / resolution.scale;
    }
    
    [node setValue:[NSNumber numberWithFloat:absF ] forKey:prop];
    
    [node setExtraProp:[NSNumber numberWithFloat:f] forKey:prop];
    [node setExtraProp:[NSNumber numberWithInt:type] forKey:[prop stringByAppendingString:@"Type"]];
}

+ (float) floatScaleForNode:(CCNode*)node prop:(NSString*)prop
{
    NSNumber* scale = [node extraPropForKey:prop];
    if (!scale) return [[node valueForKey:prop] floatValue];
    return [scale floatValue];
}

+ (int) floatScaleTypeForNode:(CCNode*)node prop:(NSString*)prop
{
    return [[node extraPropForKey:[NSString stringWithFormat:@"%@Type", prop]] intValue];
}

@end
