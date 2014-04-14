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

#import "CCBWriterInternal.h"
#import "CCBReaderInternalV1.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "TexturePropertySetter.h"
#import "PositionPropertySetter.h"
#import "StringPropertySetter.h"
#import "CCNode+NodeInfo.h"
#import "AppDelegate.h"
#import "NodePhysicsBody.h"

@protocol CCBWriterInternal_UndeclaredSelectors <NSObject>
- (NSArray*) ccbExcludePropertiesForSave;
@end

@implementation CCBWriterInternal



#pragma mark Shortcuts for serializing properties

+ (id) serializePoint:(CGPoint)pt
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:pt.x],
            [NSNumber numberWithFloat:pt.y],
            nil];
}

+ (id) serializePoint:(CGPoint)pt lock:(BOOL)lock type:(int)type
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:pt.x],
            [NSNumber numberWithFloat:pt.y],
            [NSNumber numberWithBool:lock],
            [NSNumber numberWithInt:type],
            nil];
}

+ (id) serializePosition:(NSPoint)pt type:(CCPositionType)type
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:pt.x],
            [NSNumber numberWithFloat:pt.y],
            [NSNumber numberWithInt:type.corner],
            [NSNumber numberWithInt:type.xUnit],
            [NSNumber numberWithInt:type.yUnit],
            nil];
}

+ (id) serializeSize:(CGSize)size
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:size.width],
            [NSNumber numberWithFloat:size.height],
            nil];
}

+ (id) serializeSize:(NSSize)size type:(CCSizeType)type
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:size.width],
            [NSNumber numberWithFloat:size.height],
            [NSNumber numberWithInt:type.widthUnit],
            [NSNumber numberWithInt:type.heightUnit],
            nil];
}

+ (id) serializeBoolPairX:(BOOL)x Y:(BOOL)y
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithBool:x],
            [NSNumber numberWithBool:y],
            nil];
}

+ (id) serializeFloat:(float)f
{
    return [NSNumber numberWithFloat:f];
}

+ (id) serializeInt:(float)d
{
    return [NSNumber numberWithInt:d];
}

+ (id) serializeBool:(float)b
{
    return [NSNumber numberWithBool:b];
}

+ (id) serializeSpriteFrame:(NSString*)spriteFile sheet:(NSString*)spriteSheetFile
{
    if (!spriteFile)
    {
        spriteFile = @"";
    }
    if (!spriteSheetFile || [spriteSheetFile isEqualToString:kCCBUseRegularFile])
    {
        spriteSheetFile = @"";
    }
    return [NSArray arrayWithObjects:spriteSheetFile, spriteFile, nil];
}

+ (id) serializeAnimation:(NSString*)spriteFile file:(NSString*)spriteSheetFile
{
    if (!spriteFile)
    {
        spriteFile = @"";
    }
    if (!spriteSheetFile || [spriteSheetFile isEqualToString:kCCBUseRegularFile])
    {
        spriteSheetFile = @"";
    }
    return [NSArray arrayWithObjects:spriteSheetFile, spriteFile, nil];
}

+ (id) serializeColor4:(CCColor*)c
{
    float r,g,b,a;
    [c getRed:&r green:&g blue:&b alpha:&a];
    
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:r],
            [NSNumber numberWithFloat:g],
            [NSNumber numberWithFloat:b],
            [NSNumber numberWithFloat:a],
            nil];
}

+ (id) serializeBlendFunc:(ccBlendFunc)bf
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithInt:bf.src],
            [NSNumber numberWithInt:bf.dst],
            nil];
}

+ (id) serializeFloatScale:(float)f type:(int)type
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:f],
            [NSNumber numberWithInt:type],
            nil];
}

#pragma mark Writer

+ (id) serializePropertyForNode:(CCNode*) node propInfo:(NSMutableDictionary*) propInfo excludeProps:(NSArray*) excludeProps
{
    NodeInfo* info = node.userObject;
    PlugInNode* plugIn = info.plugIn;
    NSMutableDictionary* extraProps = info.extraProps;
    
    NSString* type = [propInfo objectForKey:@"type"];
    NSString* name = [propInfo objectForKey:@"name"];
    //NSString* platform = [propInfo objectForKey:@"platform"];
    BOOL readOnly = [[propInfo objectForKey:@"readOnly"] boolValue];
    //BOOL hasKeyframes = [node hasKeyframesForProperty:name];
    //id defaultSerialization = [propInfo objectForKey:@"defaultSerialization"];
    id serializedValue = NULL;
    
    BOOL useFlashSkews = [node usesFlashSkew];
    if (useFlashSkews && [name isEqualToString:@"rotation"]) return NULL;
    if (!useFlashSkews && [name isEqualToString:@"rotationalSkewX"]) return NULL;
    if (!useFlashSkews && [name isEqualToString:@"rotationalSkewY"]) return NULL;
    
    // Check if this property should be excluded
    if (excludeProps && [excludeProps indexOfObject:name] != NSNotFound)
    {
        return NULL;
    }
    
    // Ignore separators and graphical stuff
    if ([type isEqualToString:@"Separator"]
        || [type isEqualToString:@"SeparatorSub"]
        || [type isEqualToString:@"StartStop"])
    {
        return NULL;
    }
    
    // Ignore read only properties
    if (readOnly)
    {
        return NULL;
    }
    
    // Handle different type of properties
    if ([plugIn dontSetInEditorProperty:name])
    {
        // Get the serialized value from the extra props
        serializedValue = [extraProps objectForKey:name];
    }
    else if ([type isEqualToString:@"Position"])
    {
        NSPoint pt = [PositionPropertySetter positionForNode:node prop:name];
        CCPositionType type = [PositionPropertySetter positionTypeForNode:node prop:name];
        serializedValue = [CCBWriterInternal serializePosition:pt type:type];
    }
    else if([type isEqualToString:@"Point"]
            || [type isEqualToString:@"PointLock"])
    {
        CGPoint pt = NSPointToCGPoint( [[node valueForKey:name] pointValue] );
        serializedValue = [CCBWriterInternal serializePoint:pt];
    }
    else if ([type isEqualToString:@"Size"])
    {
        //CGSize size = NSSizeToCGSize( [[node valueForKey:name] sizeValue] );
        NSSize size = [PositionPropertySetter sizeForNode:node prop:name];
        CCSizeType type = [PositionPropertySetter sizeTypeForNode:node prop:name];
        serializedValue = [CCBWriterInternal serializeSize:size type:type];
    }
    else if ([type isEqualToString:@"FloatXY"])
    {
        float x = [[node valueForKey:[NSString stringWithFormat:@"%@X",name]] floatValue];
        float y = [[node valueForKey:[NSString stringWithFormat:@"%@Y",name]] floatValue];
        serializedValue = [CCBWriterInternal serializePoint:ccp(x,y)];
    }
    else if ([type isEqualToString:@"ScaleLock"])
    {
        float x = [PositionPropertySetter scaleXForNode:node prop:name];
        float y = [PositionPropertySetter scaleYForNode:node prop:name];
        BOOL lock = [[extraProps objectForKey:[NSString stringWithFormat:@"%@Lock",name]] boolValue];
        int scaleType = [PositionPropertySetter scaledFloatTypeForNode:node prop:name];
        
        serializedValue = [CCBWriterInternal serializePoint:ccp(x,y) lock:lock type: scaleType];
    }
    else if ([type isEqualToString:@"Float"]
             || [type isEqualToString:@"Degrees"])
    {
        float f = [[node valueForKey:name] floatValue];
        serializedValue = [CCBWriterInternal serializeFloat:f];
    }
    else if([type isEqualToString:@"FloatCheck"] || [type isEqualToString:@"EnabledFloat"])
    {
        float f = [[node valueForKey:name] floatValue];
        BOOL  enabled = [[node valueForKey:[NSString stringWithFormat:@"%@Enabled",name]] boolValue];
        
        serializedValue = [NSArray arrayWithObjects:
                           [CCBWriterInternal serializeFloat:f],
                           [CCBWriterInternal serializeBool:enabled],
                           nil];
    }
    else if ([type isEqualToString:@"FloatScale"])
    {
        float f = [PositionPropertySetter floatScaleForNode:node prop:name];
        int type = [PositionPropertySetter floatScaleTypeForNode:node prop:name];
        serializedValue = [CCBWriterInternal serializeFloatScale:f type:type];
    }
    else if ([type isEqualToString:@"FloatVar"])
    {
        float x = [[node valueForKey:name] floatValue];
        float y = [[node valueForKey:[NSString stringWithFormat:@"%@Var",name]] floatValue];
        serializedValue = [CCBWriterInternal serializePoint:ccp(x,y)];
    }
    else if ([type isEqualToString:@"Integer"]
             || [type isEqualToString:@"IntegerLabeled"]
             || [type isEqualToString:@"Byte"])
    {
        int d = [[node valueForKey:name] intValue];
        serializedValue = [CCBWriterInternal serializeInt:d];
    }
    else if ([type isEqualToString:@"Check"])
    {
        BOOL check = [[node valueForKey:name] boolValue];
        serializedValue = [CCBWriterInternal serializeBool:check];
    }
    else if ([type isEqualToString:@"Flip"])
    {
        BOOL x = [[node valueForKey:[NSString stringWithFormat:@"%@X",name]] boolValue];
        BOOL y = [[node valueForKey:[NSString stringWithFormat:@"%@Y",name]] boolValue];
        serializedValue = [CCBWriterInternal serializeBoolPairX:x Y:y];
    }
    else if ([type isEqualToString:@"SpriteFrame"])
    {
        NSString* spriteFile = [extraProps objectForKey:name];
        NSString* spriteSheetFile = [extraProps objectForKey:[NSString stringWithFormat:@"%@Sheet",name]];
        serializedValue = [CCBWriterInternal serializeSpriteFrame:spriteFile sheet:spriteSheetFile];
    }
    else if ([type isEqualToString:@"Animation"])
    {
        NSString* animation = [extraProps objectForKey:name];
        NSString* animationFile = [extraProps objectForKey:[NSString stringWithFormat:@"%@Animation",name]];
        serializedValue = [CCBWriterInternal serializeAnimation:animation file:animationFile];
    }
    else if ([type isEqualToString:@"Texture"])
    {
        NSString* spriteFile = [extraProps objectForKey:name];
        if (!spriteFile) spriteFile = @"";
        
        serializedValue = spriteFile;
    }
    else if ([type isEqualToString:@"Color3"])
    {
        CCColor* colorValue = [node valueForKey:name];
        serializedValue = [CCBWriterInternal serializeColor4:colorValue];
    }
    else if ([type isEqualToString:@"Color4"])
    {
        CCColor* colorValue = [node valueForKey:name];
        serializedValue = [CCBWriterInternal serializeColor4:colorValue];
    }
    else if ([type isEqualToString:@"Color4FVar"])
    {
        NSString* nameVar = [NSString stringWithFormat:@"%@Var",name];
        CCColor* cValue = [node valueForKey:name];
        CCColor* cVarValue = [node valueForKey:nameVar];
        
        serializedValue = [NSArray arrayWithObjects:
                           [CCBWriterInternal serializeColor4:cValue],
                           [CCBWriterInternal serializeColor4:cVarValue],
                           nil];
    }
    else if ([type isEqualToString:@"Blendmode"])
    {
        NSValue* blendValue = [node valueForKey:name];
        ccBlendFunc bf;
        [blendValue getValue:&bf];
        serializedValue = [CCBWriterInternal serializeBlendFunc:bf];
    }
    else if ([type isEqualToString:@"FntFile"])
    {
        NSString* str = [node extraPropForKey:name];
        if (!str) str = @"";
        serializedValue = str;
    }
    else if ([type isEqualToString:@"StringSimple"])
    {
        NSString* str = [StringPropertySetter stringForNode:node andProp:name];
        if (!str) str = @"";
        serializedValue = str;
    }
    
    else if ([type isEqualToString:@"Text"]
             || [type isEqualToString:@"String"])
    {
        NSString* str = [StringPropertySetter stringForNode:node andProp:name];
        BOOL localized = [StringPropertySetter isLocalizedNode:node andProp:name];
        if (!str) str = @"";
        serializedValue = [NSArray arrayWithObjects:str, [NSNumber numberWithBool:localized], nil];
    }
    else if ([type isEqualToString:@"FontTTF"])
    {
        NSString* str = [TexturePropertySetter ttfForNode:node andProperty:name];
        if (!str) str = @"";
        serializedValue = str;
    }
    else if ([type isEqualToString:@"Block"])
    {
        NSString* selector = [extraProps objectForKey:name];
        NSNumber* target = [extraProps objectForKey:[NSString stringWithFormat:@"%@Target",name]];
        if (!selector) selector = @"";
        if (!target) target = [NSNumber numberWithInt:0];
        serializedValue = [NSArray arrayWithObjects:
                           selector,
                           target,
                           nil];
    }
    else if ([type isEqualToString:@"BlockCCControl"])
    {
        NSString* selector = [extraProps objectForKey:name];
        NSNumber* target = [extraProps objectForKey:[NSString stringWithFormat:@"%@Target",name]];
        NSNumber* ctrlEvts = [extraProps objectForKey:[NSString stringWithFormat:@"%@CtrlEvts",name]];
        if (!selector) selector = @"";
        if (!target) target = [NSNumber numberWithInt:0];
        if (!ctrlEvts) ctrlEvts = [NSNumber numberWithInt:0];
        serializedValue = [NSArray arrayWithObjects:
                           selector,
                           target,
                           ctrlEvts,
                           nil];
    }
    else if ([type isEqualToString:@"CCBFile"])
    {
        NSString* spriteFile = [extraProps objectForKey:name];
        if (!spriteFile) spriteFile = @"";
        serializedValue = spriteFile;
    }
    else if([type isEqualToString:@"NodeReference"])
    {
         CCNode* nodeRef = [node valueForKey:name];
         if(nodeRef)
         {
             serializedValue = @(nodeRef.UUID);
         }
    }
    else
    {
        NSLog(@"WARNING Unrecognized property type: %@", type);
    }
    
    return serializedValue;
}

+ (NSMutableDictionary*) dictionaryFromCCObject:(CCNode *)node
{
    NodeInfo* info = node.userObject;
    PlugInNode* plugIn = info.plugIn;
    NSMutableDictionary* extraProps = info.extraProps;
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSMutableArray* props = [NSMutableArray array];
    
    // Get list of properties to exclude from save (if any)
    NSArray* excludeProps = NULL;
    if ([node respondsToSelector:@selector(ccbExcludePropertiesForSave)])
    {
        excludeProps = [node performSelector:@selector(ccbExcludePropertiesForSave)];
    }
    
    NSMutableArray* plugInProps = plugIn.nodeProperties;
    int plugInPropsCount = [plugInProps count];
    for (int i = 0; i < plugInPropsCount; i++)
    {
        NSMutableDictionary* propInfo = [plugInProps objectAtIndex:i];
        NSString* type = [propInfo objectForKey:@"type"];
        NSString* name = [propInfo objectForKey:@"name"];
        NSString* platform = [propInfo objectForKey:@"platform"];
        BOOL hasKeyframes = [node hasKeyframesForProperty:name];
        id defaultSerialization = [propInfo objectForKey:@"defaultSerialization"];
        id serializedValue = NULL;
        
        serializedValue = [CCBWriterInternal serializePropertyForNode:node propInfo:propInfo excludeProps:excludeProps];
        if (!serializedValue) continue;
        
        // Skip default values
        if ([serializedValue isEqual:defaultSerialization] && !hasKeyframes)
        {
            continue;
        }
        
        NSMutableDictionary* prop = [NSMutableDictionary dictionary];
        
        [prop setValue:type forKey:@"type"];
        [prop setValue:name forKey:@"name"];
        [prop setValue:serializedValue forKey:@"value"];
        if (platform) [prop setValue:platform forKey:@"platform"];
        
        if (hasKeyframes)
        {
            // Write base value only if there are keyframes
            id baseValue = [node baseValueForProperty:name];
            if (baseValue) [prop setValue:baseValue forKey:@"baseValue"];
        }
        
        [props addObject:prop];
    }
    
    NSString* baseClass = plugIn.nodeClassName;
    
    // Children
    NSMutableArray* children = [NSMutableArray array];
    
    // Visit all children of this node
    if (plugIn.canHaveChildren)
    {
        for (int i = 0; i < [[node children] count]; i++)
        {
            [children addObject:[CCBWriterInternal dictionaryFromCCObject:[[node children] objectAtIndex:i]]];
        }
    }
    
    // Create node
    [dict setObject:props forKey:@"properties"];
    [dict setObject:baseClass forKey:@"baseClass"];
    [dict setObject:children forKey:@"children"];
    
    // Serialize any animations
    id anim = [node serializeAnimatedProperties];
    if (anim)
    {
        [dict setObject:anim forKey:@"animatedProperties"];
    }
    if (node.seqExpanded)
    {
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"seqExpanded"];
    }
    
    // Custom display names
    if (node.displayName)
    {
        [dict setObject:node.displayName forKey:@"displayName"];
    }
    
    // Custom properties
    id customProps = [node serializeCustomProperties];
    if (customProps)
    {
        [dict setObject:customProps forKey:@"customProperties"];
    }
    
    // Support for Flash skews
    if (node.usesFlashSkew)
    {
        [dict setValue:[NSNumber numberWithBool:YES] forKey:@"usesFlashSkew"];
    }
    
    // Physics
    if (node.nodePhysicsBody)
    {
        [dict setValue:[node.nodePhysicsBody serialization] forKey:@"physicsBody"];
    }
    
    //hidden node graph
    if(node.hidden)
    {
        [dict setValue:[NSNumber numberWithBool:YES] forKey:@"hidden"];
    }

    //locked node graph
    if(node.locked)
    {
        [dict setValue:[NSNumber numberWithBool:YES] forKey:@"locked"];
    }
    
    if(node.UUID)
    {
        dict[@"UUID"] = @(node.UUID);
    }
    

    
    // Selection
    NSArray* selection = [AppDelegate appDelegate].selectedNodes;
    if (selection && [selection containsObject:node])
    {
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"selected"];
    }
    
    // Add code connection props
    NSString* customClass = [extraProps objectForKey:@"customClass"];
    if (!customClass) customClass = @"";
    NSString* memberVarName = [extraProps objectForKey:@"memberVarAssignmentName"];
    if (!memberVarName) memberVarName = @"";
    int memberVarType = [[extraProps objectForKey:@"memberVarAssignmentType"] intValue];
    
    [dict setObject:customClass forKey:@"customClass"];
    [dict setObject:memberVarName forKey:@"memberVarAssignmentName"];
    [dict setObject:[NSNumber numberWithInt:memberVarType] forKey:@"memberVarAssignmentType"];
    
    // JS code connections
    NSString* jsController = [extraProps objectForKey:@"jsController"];
    if (jsController && ![jsController isEqualToString:@""])
    {
        [dict setObject:jsController forKey:@"jsController"];
    }
    
    return dict;
}

@end
