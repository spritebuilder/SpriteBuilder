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

+ (void) setPosition:(NSPoint)pos type:(CCPositionType)type forNode:(CCNode*) node prop:(NSString*)prop
{
    // Set the position type
    NSValue* typeValue = [NSValue value:&type withObjCType:@encode(CCPositionType)];
    [node setValue:typeValue forKey:[prop stringByAppendingString:@"Type"]];
    
    // Set position
    [node setValue:[NSValue valueWithPoint:pos] forKey:prop];
}

+ (void) addPositionKeyframeForNode:(CCNode*)node
{
    NSPoint newPos = [PositionPropertySetter positionForNode:node prop:@"position"];
    
    // Update animated value
    NSArray* animValue = @[@((float) newPos.x), @((float) newPos.y)];
    
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
            nodeInfo.baseValues[@"position"] = animValue;
        }
    }
}

+ (void) setPosition:(NSPoint)pos forNode:(CCNode *)node prop:(NSString *)prop
{
    [node setValue:[NSValue valueWithPoint:pos] forKey:prop];
}

+ (void) setPositionType:(CCPositionType)type oldPositionType:(CCPositionType)oldPositionType forNode:(CCNode*)node prop:(NSString*)prop
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
    
    NSArray* affectedProps = [properties[prop] objectForKey:@"affectsProperties"];
    NSMutableArray* propsToUpdate = [affectedProps mutableCopy];
    if (!propsToUpdate) propsToUpdate = [NSMutableArray array];
    
    for (int i = (int) (propsToUpdate.count -1); i >= 0; i--)
    {
        NSString* canditate = propsToUpdate[(NSUInteger) i];
        BOOL removeCandidate = NO;
        
        // Remove candidates that are read only
        if ([[properties[canditate] objectForKey:@"readOnly"] boolValue])
        {
            removeCandidate = YES;
        }
        
        // Remove candidates that are not size type
        if (![[properties[canditate] objectForKey:@"type"] isEqualToString:@"Size"])
        {
            removeCandidate = YES;
        }

        if (removeCandidate)
        {
            [propsToUpdate removeObjectAtIndex:(NSUInteger) i];
        }
    }
    
    // Always update this property
    [propsToUpdate addObject:prop];

    // Update the values
    NSMutableArray* absSizes = [NSMutableArray array];
    
    for (NSString *aProp in propsToUpdate)
    {
        // Get absolute size
        CGSize oldSize = [PositionPropertySetter sizeForNode:node prop:aProp];
        CGSize absSize = [node convertContentSizeToPoints:oldSize type:[self sizeTypeForNode:node prop:aProp]];
        
        [absSizes addObject:[NSValue valueWithSize:absSize]];
    }
    
    // Change the type
    NSValue* typeValue = [NSValue value:&type withObjCType:@encode(CCSizeType)];
    [node setValue:typeValue forKey:[prop stringByAppendingString:@"Type"]];
    
    int i = 0;
    for (NSString *aProp in propsToUpdate)
    {
        // Calculate relative size for new type
        CGSize absSize = [absSizes[(NSUInteger) i] sizeValue];
        CGSize newSize = [node convertContentSizeFromPoints:absSize type:[self sizeTypeForNode:node prop:aProp]];

        [node setValue:[NSValue valueWithSize:newSize] forKey:aProp];
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

+ (void) setScaledX:(float)scaleX Y:(float)scaleY type:(int)type forNode:(CCNode*)node prop:(NSString*)prop
{
    AppDelegate* ad = [AppDelegate appDelegate];
    int currentResolution = ad.currentDocument.currentResolution;
    ResolutionSetting* resolution = ad.currentDocument.resolutions[(NSUInteger) currentResolution];
    
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
    
    [node willChangeValueForKey:[prop stringByAppendingString:@"X"]];
    [node setValue:@(absScaleX) forKey:[prop stringByAppendingString:@"X"]];
    [node didChangeValueForKey:[prop stringByAppendingString:@"X"]];
    
    [node willChangeValueForKey:[prop stringByAppendingString:@"Y"]];
    [node setValue:@(absScaleY) forKey:[prop stringByAppendingString:@"Y"]];
    [node didChangeValueForKey:[prop stringByAppendingString:@"Y"]];

    [node setExtraProp:@(scaleX) forKey:[prop stringByAppendingString:@"X"]];
    [node setExtraProp:@(scaleY) forKey:[prop stringByAppendingString:@"Y"]];
    [node setExtraProp:@(type) forKey:[NSString stringWithFormat:@"%@Type", prop]];
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
    ResolutionSetting* resolution = ad.currentDocument.resolutions[(NSUInteger) currentResolution];
    
    float absF = f;
    if (type == kCCBScaleTypeMultiplyResolution)
    {
        absF = f / resolution.scale;
    }

    [node setValue:@(absF) forKey:prop];

    [node setExtraProp:@(f) forKey:prop];
    [node setExtraProp:@(type) forKey:[prop stringByAppendingString:@"Type"]];
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
