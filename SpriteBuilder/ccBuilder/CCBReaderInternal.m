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

#import "CCBReaderInternal.h"
#import "CCBReaderInternalV1.h"
#import "PlugInManager.h"
#import "PlugInNode.h"
#import "NodeInfo.h"
#import "CCBWriterInternal.h"
#import "TexturePropertySetter.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"
#import "ResourceManager.h"
#import "NodeGraphPropertySetter.h"
#import "PositionPropertySetter.h"
#import "StringPropertySetter.h"
#import "CCNode+NodeInfo.h"
#import "NodePhysicsBody.h"
#import "CCBUtil.h"

// Old positioning constants
enum
{
    kCCBPositionTypeRelativeBottomLeft,
    kCCBPositionTypeRelativeTopLeft,
    kCCBPositionTypeRelativeTopRight,
    kCCBPositionTypeRelativeBottomRight,
    kCCBPositionTypePercent,
    kCCBPositionTypeMultiplyResolution,
};

enum
{
    kCCBSizeTypeAbsolute,
    kCCBSizeTypePercent,
    kCCBSizeTypeRelativeContainer,
    kCCBSizeTypeHorizontalPercent,
    kCCBSzieTypeVerticalPercent,
    kCCBSizeTypeMultiplyResolution,
};

__strong NSDictionary* renamedProperties = nil;

@implementation CCBReaderInternal

+ (NSPoint) deserializePoint:(id) val
{
    float x = [[val objectAtIndex:0] floatValue];
    float y = [[val objectAtIndex:1] floatValue];
    return NSMakePoint(x,y);
}

+ (NSSize) deserializeSize:(id) val
{
    float w = [[val objectAtIndex:0] floatValue];
    float h = [[val objectAtIndex:1] floatValue];
    return NSMakeSize(w, h);
}

+ (float) deserializeFloat:(id) val
{
    return [val floatValue];
}

+ (int) deserializeInt:(id) val
{
    return [val intValue];
}

+ (BOOL) deserializeBool:(id) val
{
    return [val boolValue];
}

+ (CCColor*) deserializeColor4:(id) val
{
    CGFloat r,g,b,a;
    r = [[val objectAtIndex:0] floatValue];
    g = [[val objectAtIndex:1] floatValue];
    b = [[val objectAtIndex:2] floatValue];
    a = [[val objectAtIndex:3] floatValue];
    return [CCColor colorWithRed:r green:g blue:b alpha:a];
}

+ (ccBlendFunc) deserializeBlendFunc:(id) val
{
    ccBlendFunc bf;
    bf.src = [[val objectAtIndex:0] intValue];
    bf.dst = [[val objectAtIndex:1] intValue];
    return bf;
}

+ (void) setProp:(NSString*)name ofType:(NSString*)type toValue:(id)serializedValue forNode:(CCNode*)node parentSize:(CGSize)parentSize withParentGraph:(CCNode*)parentGraph
{
    // Handle removed ignoreAnchorPointForPosition property
    if ([name isEqualToString:@"ignoreAnchorPointForPosition"]) return;
    
    // Fetch info and extra properties
    NodeInfo* nodeInfo = node.userObject;
    NSMutableDictionary* extraProps = nodeInfo.extraProps;
    
    if ([type isEqualToString:@"Position"])
    {
        float x = [[serializedValue objectAtIndex:0] floatValue];
        float y = [[serializedValue objectAtIndex:1] floatValue];
        CCPositionType posType = CCPositionTypePoints;
        if ([(NSArray*)serializedValue count] == 3)
        {
            // Position is stored in old format - do conversion
            int oldPosType = [[serializedValue objectAtIndex:2] intValue];
            if (oldPosType == kCCBPositionTypeRelativeBottomLeft) posType.corner = CCPositionReferenceCornerBottomLeft;
            else if (oldPosType == kCCBPositionTypeRelativeTopLeft) posType.corner = CCPositionReferenceCornerTopLeft;
            else if (oldPosType == kCCBPositionTypeRelativeTopRight) posType.corner = CCPositionReferenceCornerTopRight;
            else if (oldPosType == kCCBPositionTypeRelativeBottomRight) posType.corner = CCPositionReferenceCornerBottomRight;
            else if (oldPosType == kCCBPositionTypePercent)
            {
                posType = CCPositionTypeNormalized;
                x /= 100.0;
                y /= 100.0;
            }
            else if (oldPosType == kCCBPositionTypeMultiplyResolution)
            {
                posType = CCPositionTypeUIPoints;
            }
        }
        else if ([(NSArray*)serializedValue count] == 5)
        {
            // New positioning type
            posType.corner = [[serializedValue objectAtIndex:2] intValue];
            posType.xUnit = [[serializedValue objectAtIndex:3] intValue];
            posType.yUnit = [[serializedValue objectAtIndex:4] intValue];
        }
        [PositionPropertySetter setPosition:NSMakePoint(x, y) type:posType forNode:node prop:name];
    }
    else if ([type isEqualToString:@"Point"]
        || [type isEqualToString:@"PointLock"])
    {
        NSPoint pt = [CCBReaderInternal deserializePoint: serializedValue];
		
        [node setValue:[NSValue valueWithPoint:pt] forKey:name];
    }
    else if ([type isEqualToString:@"Size"])
    {
        float w = [[serializedValue objectAtIndex:0] floatValue];
        float h = [[serializedValue objectAtIndex:1] floatValue];
        
        CCSizeType sizeType = CCSizeTypePoints;
        if ([(NSArray*)serializedValue count] == 3)
        {
            // Convert old content size type
            int oldSizeType = [[serializedValue objectAtIndex:2] intValue];
            if (oldSizeType == kCCBSizeTypePercent)
            {
                sizeType = CCSizeTypeNormalized;
                w /= 100.0f;
                h /= 100.0f;
            }
            else if (oldSizeType == kCCBSizeTypeRelativeContainer)
            {
                sizeType.widthUnit = CCSizeUnitInsetPoints;
                sizeType.heightUnit = CCSizeUnitInsetPoints;
            }
            else if (oldSizeType == kCCBSizeTypeHorizontalPercent)
            {
                sizeType.widthUnit = CCSizeUnitNormalized;
                w /= 100.0f;
            }
            else if (oldSizeType == kCCBSzieTypeVerticalPercent)
            {
                sizeType.heightUnit = CCSizeUnitNormalized;
                h /= 100.0f;
            }
            else if (oldSizeType == kCCBSizeTypeMultiplyResolution)
            {
                sizeType = CCSizeTypeUIPoints;
            }
        }
        else if ([(NSArray*)serializedValue count] == 4)
        {
            // Uses new content size type
            sizeType.widthUnit = [[serializedValue objectAtIndex:2] intValue];
            sizeType.heightUnit = [[serializedValue objectAtIndex:3] intValue];
        }
        
        NSSize size =  NSMakeSize(w, h);
        [PositionPropertySetter setSize:size type:sizeType forNode:node prop:name];
    }
    else if ([type isEqualToString:@"Scale"]
             || [type isEqualToString:@"ScaleLock"])
    {
        float x = [[serializedValue objectAtIndex:0] floatValue];
        float y = [[serializedValue objectAtIndex:1] floatValue];
        int scaleType = 0;
        if ([(NSArray*)serializedValue count] >= 3)
        {
            [extraProps setValue:[serializedValue objectAtIndex:2] forKey:[NSString stringWithFormat:@"%@Lock",name]];
            if ([(NSArray*)serializedValue count] == 4)
            {
                scaleType = [[serializedValue objectAtIndex:3] intValue];
            }
        }
        [PositionPropertySetter setScaledX:x Y:y type:scaleType forNode:node prop:name];
    }
    else if ([type isEqualToString:@"FloatXY"])
    {
        float x = [[serializedValue objectAtIndex:0] floatValue];
        float y = [[serializedValue objectAtIndex:1] floatValue];
        [node setValue:[NSNumber numberWithFloat:x] forKey:[name stringByAppendingString:@"X"]];
        [node setValue:[NSNumber numberWithFloat:y] forKey:[name stringByAppendingString:@"Y"]];
    }
    else if ([type isEqualToString:@"Float"]
             || [type isEqualToString:@"Degrees"])
    {
        float f = [CCBReaderInternal deserializeFloat: serializedValue];
        [node setValue:[NSNumber numberWithFloat:f] forKey:name];
    }
    else if ([type isEqualToString:@"FloatCheck"] || [type isEqualToString:@"EnabledFloat"] )
    {
        float f = [[serializedValue objectAtIndex:0] floatValue];
        float enabled = [[serializedValue objectAtIndex:1] boolValue];
      
        [node setValue:[NSNumber numberWithBool:enabled] forKey:[NSString stringWithFormat:@"%@Enabled",name]];
        [node setValue:[NSNumber numberWithFloat:f] forKey:name];

    }
    else if ([type isEqualToString:@"FloatScale"])
    {
        float f = 0;
        int type = 0;
        if ([serializedValue isKindOfClass:[NSNumber class]])
        {
            // Support for old files
            f = [serializedValue floatValue];
        }
        else
        {
            f = [[serializedValue objectAtIndex:0] floatValue];
            type = [[serializedValue objectAtIndex:1] intValue];
        }
        [PositionPropertySetter setFloatScale:f type:type forNode:node prop:name];
    }
    else if ([type isEqualToString:@"FloatVar"])
    {
        [node setValue:[serializedValue objectAtIndex:0] forKey:name];
        [node setValue:[serializedValue objectAtIndex:1] forKey:[NSString stringWithFormat:@"%@Var",name]];
    }
    else if ([type isEqualToString:@"Integer"]
             || [type isEqualToString:@"IntegerLabeled"]
             || [type isEqualToString:@"Byte"])
    {
        int d = [CCBReaderInternal deserializeInt: serializedValue];
        [node setValue:[NSNumber numberWithInt:d] forKey:name];
    }
    else if ([type isEqualToString:@"Check"])
    {
        BOOL check = [CCBReaderInternal deserializeBool:serializedValue];
        [node setValue:[NSNumber numberWithBool:check] forKey:name];
    }
    else if ([type isEqualToString:@"Flip"])
    {
        [node setValue:[serializedValue objectAtIndex:0] forKey:[NSString stringWithFormat:@"%@X",name]];
        [node setValue:[serializedValue objectAtIndex:1] forKey:[NSString stringWithFormat:@"%@Y",name]];
    }
    else if ([type isEqualToString:@"SpriteFrame"])
    {
        NSString* spriteSheetFile = [serializedValue objectAtIndex:0];
        NSString* spriteFile = [serializedValue objectAtIndex:1];
        if (!spriteSheetFile || [spriteSheetFile isEqualToString:@""])
        {
            spriteSheetFile = kCCBUseRegularFile;
        }
        
        [extraProps setObject:spriteSheetFile forKey:[NSString stringWithFormat:@"%@Sheet",name]];
        [extraProps setObject:spriteFile forKey:name];
        [TexturePropertySetter setSpriteFrameForNode:node andProperty:name withFile:spriteFile andSheetFile:spriteSheetFile];
    }
    else if ([type isEqualToString:@"Texture"])
    {
        NSString* spriteFile = serializedValue;
        if (!spriteFile) spriteFile = @"";
        [TexturePropertySetter setTextureForNode:node andProperty:name withFile:spriteFile];
        [extraProps setObject:spriteFile forKey:name];
    }
    else if ([type isEqualToString:@"Color4"] ||
             [type isEqualToString:@"Color3"])
    {
        CCColor* colorValue = [CCBReaderInternal deserializeColor4:serializedValue];
        [node setValue:colorValue forKey:name];
    }
    else if ([type isEqualToString:@"Color4FVar"])
    {
        CCColor* cValue = [CCBReaderInternal deserializeColor4:[serializedValue objectAtIndex:0]];
        CCColor* cVarValue = [CCBReaderInternal deserializeColor4:[serializedValue objectAtIndex:1]];
        [node setValue:cValue forKey:name];
        [node setValue:cVarValue forKey:[NSString stringWithFormat:@"%@Var",name]];
    }
    else if ([type isEqualToString:@"Blendmode"])
    {
        ccBlendFunc bf = [CCBReaderInternal deserializeBlendFunc:serializedValue];
        NSValue* blendValue = [NSValue value:&bf withObjCType:@encode(ccBlendFunc)];
        [node setValue:blendValue forKey:name];
    }
    else if ([type isEqualToString:@"FntFile"])
    {
        NSString* fntFile = serializedValue;
        if (!fntFile) fntFile = @"";
        [TexturePropertySetter setFontForNode:node andProperty:name withFile:fntFile];
    }
    else if ([type isEqualToString:@"StringSimple"])
    {
        NSString* str = serializedValue;
        if (!str) str = @"";
        [node setValue:str forKey:name];
    }
    else if ([type isEqualToString:@"Text"]
             || [type isEqualToString:@"String"])
    {
        NSString* str = NULL;
        BOOL localized = NO;
        
        if ([serializedValue isKindOfClass:[NSString class]])
        {
            str = serializedValue;
        }
        else
        {
            str = [serializedValue objectAtIndex:0];
            localized = [[serializedValue objectAtIndex:1] boolValue];
        }
        
        if (!str) str = @"";
        [StringPropertySetter setString:str forNode:node andProp:name];
        [StringPropertySetter setLocalized:localized forNode:node andProp:name];
    }
    else if ([type isEqualToString:@"FontTTF"])
    {
        NSString* str = serializedValue;
        if (!str) str = @"";
        [TexturePropertySetter setTtfForNode:node andProperty:name withFont:str];
    }
    else if ([type isEqualToString:@"Block"])
    {
        NSString* selector = [serializedValue objectAtIndex:0];
        NSNumber* target = [serializedValue objectAtIndex:1];
        if (!selector) selector = @"";
        if (!target) target = [NSNumber numberWithInt:0];
        [extraProps setObject: selector forKey:name];
        [extraProps setObject:target forKey:[NSString stringWithFormat:@"%@Target",name]];
    }
    else if ([type isEqualToString:@"BlockCCControl"])
    {
        NSString* selector = [serializedValue objectAtIndex:0];
        NSNumber* target = [serializedValue objectAtIndex:1];
        NSNumber* ctrlEvts = [serializedValue objectAtIndex:2];
        if (!selector) selector = @"";
        if (!target) target = [NSNumber numberWithInt:0];
        if (!ctrlEvts) ctrlEvts = [NSNumber numberWithInt:0];
        [extraProps setObject: selector forKey:name];
        [extraProps setObject:target forKey:[NSString stringWithFormat:@"%@Target",name]];
        [extraProps setObject:ctrlEvts forKey:[NSString stringWithFormat:@"%@CtrlEvts",name]];
    }
    else if ([type isEqualToString:@"CCBFile"])
    {
        NSString* ccbFile = serializedValue;
        if (!ccbFile) ccbFile = @"";
        [NodeGraphPropertySetter setNodeGraphForNode:node andProperty:name withFile:ccbFile parentSize:parentSize];
        [extraProps setObject:ccbFile forKey:name];
    }
    else if ([type isEqualToString:@"NodeReference"])
    {
        NSUInteger uuid = [serializedValue unsignedIntegerValue];
        
        if(uuid != 0x0)
        {
            NSAssert(parentGraph != nil,@"You need a parent graph handed in for a NodeReference to work");
            
            CCNode * target = [CCBUtil findNodeWithUUID:parentGraph UUID:uuid];
            if(!target)
                return;
            
            NSAssert(target != nil, @"Failed to find node with UUID %lu", (unsigned long)uuid);
            [node setValue:target forKey:name];
        }
    }
    else
    {
        NSLog(@"WARNING Unrecognized property type: %@", type);
    }
}

+ (CCNode*) nodeGraphFromDictionary:(NSDictionary*) dict parentSize:(CGSize)parentSize
{
    return [CCBReaderInternal nodeGraphFromDictionary:dict parentSize:parentSize withParentGraph:nil];
}

+ (CCNode*) nodeGraphFromDictionary:(NSDictionary*) dict parentSize:(CGSize)parentSize withParentGraph:(CCNode*)parentGraph
{
    if (!renamedProperties)
    {
        renamedProperties = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CCBReaderInternalRenamedProps" ofType:@"plist"]];
        
        NSAssert(renamedProperties, @"Failed to load renamed properties dict");
    }
    
    NSArray* props = [dict objectForKey:@"properties"];
    NSString* baseClass = [dict objectForKey:@"baseClass"];
    NSArray* children = [dict objectForKey:@"children"];
    
    // Create the node
    CCNode* node = [[PlugInManager sharedManager] createDefaultNodeOfType:baseClass];
    if (!node)
    {
        NSLog(@"WARNING! Plug-in missing for %@ - all nodes using this plugin will be removed from CCB!", baseClass);
        return nil;
    }
    
    
    // Fetch info and extra properties
    NodeInfo* nodeInfo = node.userObject;
    NSMutableDictionary* extraProps = nodeInfo.extraProps;
    PlugInNode* plugIn = nodeInfo.plugIn;
    node.UUID = [dict[@"UUID"] unsignedIntegerValue];
    
    // Flash skew compatibility
    if ([[dict objectForKey:@"usesFlashSkew"] boolValue])
    {
        [node setUsesFlashSkew:YES];
    }
    
    // Hidden node graph
    if ([[dict objectForKey:@"hidden"] boolValue])
    {
        node.hidden = YES;
    }
    
    // Locked node
    if ([[dict objectForKey:@"locked"] boolValue])
    {
        node.locked = YES;
    }
    
    // Set properties for the node
    int numProps = [props count];
    for (int i = 0; i < numProps; i++)
    {
        NSDictionary* propInfo = [props objectAtIndex:i];
        NSString* type = [propInfo objectForKey:@"type"];
        NSString* name = [propInfo objectForKey:@"name"];
        id serializedValue = [propInfo objectForKey:@"value"];
        
        // Check for renamings
        NSDictionary* renameRule = [renamedProperties objectForKey:name];
        if (renameRule)
        {
            name = [renameRule objectForKey:@"newName"];
        }
        
        if ([plugIn dontSetInEditorProperty:name])
        {
            [extraProps setObject:serializedValue forKey:name];
        }
        else
        {
            [CCBReaderInternal setProp:name ofType:type toValue:serializedValue forNode:node parentSize:parentSize withParentGraph:parentGraph];
        }
        id baseValue = [propInfo objectForKey:@"baseValue"];
        if (baseValue) [node setBaseValue:baseValue forProperty:name];
    }
    
    // Set extra properties for code connections
    NSString* customClass = [dict objectForKey:@"customClass"];
    if (!customClass) customClass = @"";
    NSString* memberVarName = [dict objectForKey:@"memberVarAssignmentName"];
    if (!memberVarName) memberVarName = @"";
    int memberVarType = [[dict objectForKey:@"memberVarAssignmentType"] intValue];
    
    [extraProps setObject:customClass forKey:@"customClass"];
    [extraProps setObject:memberVarName forKey:@"memberVarAssignmentName"];
    [extraProps setObject:[NSNumber numberWithInt:memberVarType] forKey:@"memberVarAssignmentType"];
    
    // JS code connections
    NSString* jsController = [dict objectForKey:@"jsController"];
    if (jsController)
    {
        [extraProps setObject:jsController forKey:@"jsController"];
    }
    
    NSString* displayName = [dict objectForKey:@"displayName"];
    if (displayName)
    {
        node.displayName = displayName;
    }
    
    id animatedProps = [dict objectForKey:@"animatedProperties"];
    [node loadAnimatedPropertiesFromSerialization:animatedProps];
    node.seqExpanded = [[dict objectForKey:@"seqExpanded"] boolValue];
    
    CGSize contentSize = node.contentSize;
    for (int i = 0; i < [children count]; i++)
    {
        CCNode* child = [CCBReaderInternal nodeGraphFromDictionary:[children objectAtIndex:i] parentSize:contentSize];
		
		if (child)
		{
			[node addChild:child z:i];
		}
    }
    
    // Physics
    if ([dict objectForKey:@"physicsBody"])
    {
        node.nodePhysicsBody = [[NodePhysicsBody alloc] initWithSerialization:[dict objectForKey:@"physicsBody"]];
    }
    
    // Selections
    if ([[dict objectForKey:@"selected"] boolValue])
    {
        [[AppDelegate appDelegate].loadedSelectedNodes addObject:node];
    }
    
    BOOL isCCBSubFile = [baseClass isEqualToString:@"CCBFile"];
    
    // Load custom properties
    if (isCCBSubFile)
    {
        // For sub ccb files the custom properties are already loaded by the sub file and forwarded. We just need to override the values from the sub ccb file
        [node loadCustomPropertyValuesFromSerialization:[dict objectForKey:@"customProperties"]];
    }
    else
    {
        [node loadCustomPropertiesFromSerialization:[dict objectForKey:@"customProperties"]];
    }
    
    return node;
}

+ (CCNode*) nodeGraphFromDocumentDictionary:(NSDictionary *)dict
{
    return [CCBReaderInternal nodeGraphFromDocumentDictionary:dict parentSize:CGSizeZero];
}

+ (CCNode*) nodeGraphFromDocumentDictionary:(NSDictionary *)dict parentSize:(CGSize) parentSize
{
    return [CCBReaderInternal nodeGraphFromDocumentDictionary:dict parentSize:parentSize withParentGraph:nil];
}

+ (CCNode*) nodeGraphFromDocumentDictionary:(NSDictionary *)dict parentSize:(CGSize) parentSize withParentGraph:(CCNode*)parentGraph
{
    if (!dict)
    {
        NSLog(@"WARNING! Trying to load invalid file type (dict is null)");
        return NULL;
    }
    // Load file metadata
    
    NSString* fileType = [dict objectForKey:@"fileType"];
    int fileVersion = [[dict objectForKey:@"fileVersion"] intValue];
    
    if (!fileType  || ![fileType isEqualToString:@"CocosBuilder"])
    {
        NSLog(@"WARNING! Trying to load invalid file type (%@)", fileType);
    }
    
    NSDictionary* nodeGraph = [dict objectForKey:@"nodeGraph"];
    
    if (fileVersion <= 2)
    {
        // Use legacy reader
        NSString* assetsPath = [NSString stringWithFormat:@"%@/", [[ResourceManager sharedManager] mainActiveDirectoryPath]];
        
        return [CCBReaderInternalV1 ccObjectFromDictionary:nodeGraph assetsDir:assetsPath owner:NULL];
    }
    else if (fileVersion > kCCBFileFormatVersion)
    {
        NSLog(@"WARNING! Trying to load file made with a newer version of CocosBuilder");
        return NULL;
    }
    
    return [CCBReaderInternal nodeGraphFromDictionary:nodeGraph parentSize:parentSize];
}

@end
