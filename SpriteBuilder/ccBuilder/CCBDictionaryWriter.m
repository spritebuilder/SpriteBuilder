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

#import "CCBDictionaryWriter.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "TexturePropertySetter.h"
#import "PositionPropertySetter.h"
#import "StringPropertySetter.h"
#import "CCNode+NodeInfo.h"
#import "AppDelegate.h"
#import "NodePhysicsBody.h"
#import "CCBPEffectNode.h"

@protocol CCBWriterInternal_UndeclaredSelectors <NSObject>
- (NSArray*) ccbExcludePropertiesForSave;
@end

@implementation CCBDictionaryWriter



#pragma mark Shortcuts for serializing properties

+ (id) serializePoint:(CGPoint)pt
{
    return @[@((float) pt.x),
            @((float) pt.y)];
}

+ (id) serializePoint:(CGPoint)pt lock:(BOOL)lock type:(int)type
{
    return @[@((float) pt.x),
            @((float) pt.y),
            @(lock),
            @(type)];
}

+ (id) serializePosition:(NSPoint)pt type:(CCPositionType)type
{
    return @[@((float) pt.x),
            @((float) pt.y),
            @(type.corner),
            @(type.xUnit),
            @(type.yUnit)];
}

+ (id) serializeSize:(CGSize)size
{
    return @[@((float) size.width),
            @((float) size.height)];
}

+ (id) serializeSize:(NSSize)size type:(CCSizeType)type
{
    return @[@((float) size.width),
            @((float) size.height),
            @(type.widthUnit),
            @(type.heightUnit)];
}

+ (id) serializeBoolPairX:(BOOL)x Y:(BOOL)y
{
    return @[@(x), @(y)];
}

+ (id) serializeFloat:(float)f
{
    return @(f);
}

// TODO: float type???
+ (id) serializeInt:(float)d
{
    return @((int) d);
}

// TODO: float type???
+ (id) serializeBool:(float)b
{
    return @((BOOL) b);
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
    return @[spriteSheetFile, spriteFile];
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
    return @[spriteSheetFile, spriteFile];
}

+ (id) serializeColor4:(CCColor*)c
{
    float r,g,b,a;
    [c getRed:&r green:&g blue:&b alpha:&a];
    
    return @[@(r), @(g), @(b), @(a)];
}

+ (id) serializeBlendFunc:(ccBlendFunc)bf
{
    return @[@(bf.src), @(bf.dst)];
}

+ (id) serializeBlendMode:(CCBlendMode *)blendMode
{
    return blendMode.options;
}

+ (id) serializeFloatScale:(float)f type:(int)type
{
    return @[@(f), @(type)];
}

#pragma mark Writer

+ (id)serializePropertyOfNode:(CCNode *)node propInfo:(NSMutableDictionary *)propInfo excludeProps:(NSArray*) excludeProps
{
    NodeInfo* info = node.userObject;
    PlugInNode* plugIn = info.plugIn;
    NSMutableDictionary* extraProps = info.extraProps;
    
    NSString* type = propInfo[@"type"];
    NSString* name = propInfo[@"name"];
    //NSString* platform = [propInfo objectForKey:@"platform"];
    BOOL readOnly = [propInfo[@"readOnly"] boolValue];
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
        serializedValue = extraProps[name];
    }
    else if ([type isEqualToString:@"Position"])
    {
        NSPoint pt = [PositionPropertySetter positionForNode:node prop:name];
        CCPositionType aType = [PositionPropertySetter positionTypeForNode:node prop:name];
        serializedValue = [CCBDictionaryWriter serializePosition:pt type:aType];
    }
    else if([type isEqualToString:@"Point"]
            || [type isEqualToString:@"PointLock"])
    {
        CGPoint pt = NSPointToCGPoint( [[node valueForKey:name] pointValue] );
        serializedValue = [CCBDictionaryWriter serializePoint:pt];
    }
    else if ([type isEqualToString:@"Size"])
    {
        //CGSize size = NSSizeToCGSize( [[node valueForKey:name] sizeValue] );
        NSSize size = [PositionPropertySetter sizeForNode:node prop:name];
        CCSizeType aType = [PositionPropertySetter sizeTypeForNode:node prop:name];
        serializedValue = [CCBDictionaryWriter serializeSize:size type:aType];
    }
    else if ([type isEqualToString:@"FloatXY"])
    {
        float x = [[node valueForKey:[NSString stringWithFormat:@"%@X",name]] floatValue];
        float y = [[node valueForKey:[NSString stringWithFormat:@"%@Y",name]] floatValue];
        serializedValue = [CCBDictionaryWriter serializePoint:ccp(x, y)];
    }
    else if ([type isEqualToString:@"ScaleLock"])
    {
        float x = [PositionPropertySetter scaleXForNode:node prop:name];
        float y = [PositionPropertySetter scaleYForNode:node prop:name];
        BOOL lock = [extraProps[[NSString stringWithFormat:@"%@Lock", name]] boolValue];
        int scaleType = [PositionPropertySetter scaledFloatTypeForNode:node prop:name];
        
        serializedValue = [CCBDictionaryWriter serializePoint:ccp(x, y) lock:lock type:scaleType];
    }
    else if ([type isEqualToString:@"Float"]
             || [type isEqualToString:@"Degrees"])
    {
        float f = [[node valueForKey:name] floatValue];
        serializedValue = [CCBDictionaryWriter serializeFloat:f];
    }
    else if([type isEqualToString:@"FloatCheck"] || [type isEqualToString:@"EnabledFloat"])
    {
        float f = [[node valueForKey:name] floatValue];
        BOOL  enabled = [[node valueForKey:[NSString stringWithFormat:@"%@Enabled",name]] boolValue];
        
        serializedValue = @[[CCBDictionaryWriter serializeFloat:f],
                [CCBDictionaryWriter serializeBool:enabled]];
    }
    else if ([type isEqualToString:@"FloatScale"])
    {
        float f = [PositionPropertySetter floatScaleForNode:node prop:name];
        int aType = [PositionPropertySetter floatScaleTypeForNode:node prop:name];
        serializedValue = [CCBDictionaryWriter serializeFloatScale:f type:aType];
    }
    else if ([type isEqualToString:@"FloatVar"])
    {
        float x = [[node valueForKey:name] floatValue];
        float y = [[node valueForKey:[NSString stringWithFormat:@"%@Var",name]] floatValue];
        serializedValue = [CCBDictionaryWriter serializePoint:ccp(x, y)];
    }
    else if ([type isEqualToString:@"Integer"]
             || [type isEqualToString:@"IntegerLabeled"]
             || [type isEqualToString:@"Byte"])
    {
        int d = [[node valueForKey:name] intValue];
        serializedValue = [CCBDictionaryWriter serializeInt:d];
    }
    else if ([type isEqualToString:@"Check"])
    {
        BOOL check = [[node valueForKey:name] boolValue];
        serializedValue = [CCBDictionaryWriter serializeBool:check];
    }
    else if ([type isEqualToString:@"Flip"])
    {
        BOOL x = [[node valueForKey:[NSString stringWithFormat:@"%@X",name]] boolValue];
        BOOL y = [[node valueForKey:[NSString stringWithFormat:@"%@Y",name]] boolValue];
        serializedValue = [CCBDictionaryWriter serializeBoolPairX:x Y:y];
    }
    else if ([type isEqualToString:@"SpriteFrame"])
    {
        NSString* spriteFile = extraProps[name];
        NSString* spriteSheetFile = extraProps[[NSString stringWithFormat:@"%@Sheet", name]];
        serializedValue = [CCBDictionaryWriter serializeSpriteFrame:spriteFile sheet:spriteSheetFile];
    }
    else if ([type isEqualToString:@"Animation"])
    {
        NSString* animation = extraProps[name];
        NSString* animationFile = extraProps[[NSString stringWithFormat:@"%@Animation", name]];
        serializedValue = [CCBDictionaryWriter serializeAnimation:animation file:animationFile];
    }
    else if ([type isEqualToString:@"Texture"])
    {
        NSString* spriteFile = extraProps[name];
        if (!spriteFile) spriteFile = @"";
        
        serializedValue = spriteFile;
    }
    else if ([type isEqualToString:@"Color3"])
    {
        CCColor* colorValue = [node valueForKey:name];
        serializedValue = [CCBDictionaryWriter serializeColor4:colorValue];
    }
    else if ([type isEqualToString:@"Color4"])
    {
        CCColor* colorValue = [node valueForKey:name];
        serializedValue = [CCBDictionaryWriter serializeColor4:colorValue];
    }
    else if ([type isEqualToString:@"Color4FVar"])
    {
        NSString* nameVar = [NSString stringWithFormat:@"%@Var",name];
        CCColor* cValue = [node valueForKey:name];
        CCColor* cVarValue = [node valueForKey:nameVar];
        
        serializedValue = @[[CCBDictionaryWriter serializeColor4:cValue],
                [CCBDictionaryWriter serializeColor4:cVarValue]];
    }
    else if ([type isEqualToString:@"Blendmode"])
    {
        CCBlendMode *blendMode = [node valueForKey:name];;
        serializedValue = [CCBDictionaryWriter serializeBlendMode:blendMode];
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
        serializedValue = @[str, @(localized)];
    }
    else if ([type isEqualToString:@"FontTTF"])
    {
        NSString* str = [TexturePropertySetter ttfForNode:node andProperty:name];
        if (!str) str = @"";
        serializedValue = str;
    }
    else if ([type isEqualToString:@"Block"])
    {
        NSString* selector = extraProps[name];
        NSNumber* target = extraProps[[NSString stringWithFormat:@"%@Target", name]];
        if (!selector) selector = @"";
        if (!target) target = @0;
        serializedValue = @[selector, target];
    }
    else if ([type isEqualToString:@"BlockCCControl"])
    {
        NSString* selector = extraProps[name];
        NSNumber* target = extraProps[[NSString stringWithFormat:@"%@Target", name]];
        NSNumber* ctrlEvts = extraProps[[NSString stringWithFormat:@"%@CtrlEvts", name]];
        if (!selector) selector = @"";
        if (!target) target = @0;
        if (!ctrlEvts) ctrlEvts = @0;
        serializedValue = @[selector, target, ctrlEvts];
    }
    else if ([type isEqualToString:@"CCBFile"])
    {
        NSString* spriteFile = extraProps[name];
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
	else if([type isEqualToString:@"EffectControl"])
	{
	
		NSAssert([node conformsToProtocol:@protocol(CCEffectNodeProtocol)], @"Node %@ shoudl conform to protocol CCEffectNodeProtocol",node);
		id<CCEffectNodeProtocol> effectNode = (id<CCEffectNodeProtocol>)node;

		NSMutableArray * serializedEffectsData = [NSMutableArray new];
		for (id<EffectProtocol> effect in effectNode.effects) {

			NSDictionary * effectProperties = [effect serialize];
			NSDictionary * effectDescription = @{@"className": NSStringFromClass([effect class]),
												 @"baseClass" : [effect effectDescription].baseClass,
												 @"UUID": @([effect UUID]),
												 @"properties":effectProperties
												 };
			
			[serializedEffectsData addObject:effectDescription];
		
		}
		serializedValue = serializedEffectsData;
		
	}
    else if([type isEqualToString:@"TokenArray"])
    {
        NSArray *tokens = [node valueForKey:name];
        serializedValue = tokens;
    }
    else
    {
        NSLog(@"WARNING Unrecognized property type: %@", type);
    }
    
    return serializedValue;
}

+ (NSMutableDictionary*)serializeNode:(CCNode *)node
{
    NodeInfo* info = node.userObject;
	NSAssert(info, @"Node does not have an NodeInfo");
    PlugInNode* plugIn = info.plugIn;
	NSAssert(plugIn, @"Node does not have a plugin");

	
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
    NSUInteger plugInPropsCount = [plugInProps count];
    for (NSUInteger i = 0; i < plugInPropsCount; i++)
    {
        NSMutableDictionary* propInfo = plugInProps[i];
        NSString* type = propInfo[@"type"];
        NSString* name = propInfo[@"name"];
        NSString* platform = propInfo[@"platform"];
        BOOL hasKeyframes = [node hasKeyframesForProperty:name];
        id defaultSerialization = propInfo[@"defaultSerialization"];
        id serializedValue = NULL;
        
	
        serializedValue = [CCBDictionaryWriter serializePropertyOfNode:node propInfo:propInfo excludeProps:excludeProps];
        if (!serializedValue)
			continue;
        
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
        for (NSUInteger i = 0; i < [[node children] count]; i++)
        {
			CCNode * childNode = [node children][i];
			if(!childNode.userObject)
			{
				continue;
			}
			NSDictionary * serializedChild = [CCBDictionaryWriter serializeNode:childNode];
            [children addObject:serializedChild];
        }
    }
    
    // Create node
    dict[@"properties"] = props;
    dict[@"baseClass"] = baseClass;
    dict[@"children"] = children;
    
    // Serialize any animations
    id anim = [node serializeAnimatedProperties];
    if (anim)
    {
        dict[@"animatedProperties"] = anim;
    }
    if (node.seqExpanded)
    {
        dict[@"seqExpanded"] = @YES;
    }
    
    // Custom display names
    if (node.displayName)
    {
        dict[@"displayName"] = node.displayName;
    }
    
    // Custom properties
    id customProps = [node serializeCustomProperties];
    if (customProps)
    {
        dict[@"customProperties"] = customProps;
    }
    
    // Support for Flash skews
    if (node.usesFlashSkew)
    {
        [dict setValue:@YES forKey:@"usesFlashSkew"];
    }
    
    // Physics
    if (node.nodePhysicsBody)
    {
        [dict setValue:[node.nodePhysicsBody serialization] forKey:@"physicsBody"];
    }
    
    //hidden node graph
    if(node.hidden)
    {
        [dict setValue:@YES forKey:@"hidden"];
    }

    //locked node graph
    if(node.locked)
    {
        [dict setValue:@YES forKey:@"locked"];
    }
    
    if(node.UUID)
    {
        dict[@"UUID"] = @(node.UUID);
    }
    

    
    // Selection
    NSArray* selection = [AppDelegate appDelegate].selectedNodes;
    if (selection && [selection containsObject:node])
    {
        dict[@"selected"] = @YES;
    }
    
    // Add code connection props
    NSString* customClass = extraProps[@"customClass"];
    if (!customClass) customClass = @"";
    NSString* memberVarName = extraProps[@"memberVarAssignmentName"];
    if (!memberVarName) memberVarName = @"";
    int memberVarType = [extraProps[@"memberVarAssignmentType"] intValue];
    
    dict[@"customClass"] = customClass;
    dict[@"memberVarAssignmentName"] = memberVarName;
    dict[@"memberVarAssignmentType"] = @(memberVarType);
    
    // JS code connections
    NSString* jsController = extraProps[@"jsController"];
    if (jsController && ![jsController isEqualToString:@""])
    {
        dict[@"jsController"] = jsController;
    }
    
    return dict;
}

@end
