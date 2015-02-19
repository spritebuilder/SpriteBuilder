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

#import "CCBDictionaryReader.h"
#import "PlugInManager.h"
#import "PlugInNode.h"
#import "NodeInfo.h"
#import "CCBDictionaryWriter.h"
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
#import "EffectsManager.h"
#import "NSArray+Query.h"
#import "CCBPEffectNode.h"
#import "CCBDictionaryKeys.h"
#import "CCBDictionaryMigrator.h"
#import "NSError+SBErrors.h"
#import "Errors.h"

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

@interface CCNode (Private)
-(void)postDeserializationFixup;
@end


@interface CCBDictionaryReader()

@property (nonatomic) NSUInteger fileVersion;
@property (nonatomic, strong) NSDictionary *dataDict;

@end


@implementation CCBDictionaryReader

- (instancetype)initWithDictionary:(NSDictionary *)dataDict
{
    self = [super init];

    if (self)
    {
        self.dataDict = dataDict; 
    }

    return self;
}

+ (NSPoint) deserializePoint:(id) val
{
    float x = [[val objectAtIndex:0] floatValue];
    float y = [[val objectAtIndex:1] floatValue];
    return NSMakePoint(x,y);
}

+ (NSSize) deserializeSize:(id)value sizeType:(CCSizeType *)sizeType
{
    float w = [[value objectAtIndex:0] floatValue];
    float h = [[value objectAtIndex:1] floatValue];

    if ([(NSArray*) value count] == 3)
    {
        // Convert old content size type
        int oldSizeType = [[value objectAtIndex:2] intValue];
        if (oldSizeType == kCCBSizeTypePercent)
        {
            *sizeType = CCSizeTypeNormalized;
            w /= 100.0f;
            h /= 100.0f;
        }
        else if (oldSizeType == kCCBSizeTypeRelativeContainer)
        {
            sizeType->widthUnit = CCSizeUnitInsetPoints;
            sizeType->heightUnit = CCSizeUnitInsetPoints;
        }
        else if (oldSizeType == kCCBSizeTypeHorizontalPercent)
        {
            sizeType->widthUnit = CCSizeUnitNormalized;
            w /= 100.0f;
        }
        else if (oldSizeType == kCCBSzieTypeVerticalPercent)
        {
            sizeType->heightUnit = CCSizeUnitNormalized;
            h /= 100.0f;
        }
        else if (oldSizeType == kCCBSizeTypeMultiplyResolution)
        {
            *sizeType = CCSizeTypeUIPoints;
        }
    }
    else if ([(NSArray*) value count] == 4)
    {
        // Uses new content size type
        sizeType->widthUnit = (CCSizeUnit) [[value objectAtIndex:2] intValue];
        sizeType->heightUnit = (CCSizeUnit) [[value objectAtIndex:3] intValue];
    }

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
    return [CCColor colorWithRed:(float) r green:(float) g blue:(float) b alpha:(float) a];
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
            posType.corner = (CCPositionReferenceCorner) [[serializedValue objectAtIndex:2] intValue];
            posType.xUnit = (CCPositionUnit) [[serializedValue objectAtIndex:3] intValue];
            posType.yUnit = (CCPositionUnit) [[serializedValue objectAtIndex:4] intValue];
        }
        [PositionPropertySetter setPosition:NSMakePoint(x, y) type:posType forNode:node prop:name];
    }
    else if ([type isEqualToString:@"Point"]
        || [type isEqualToString:@"PointLock"])
    {
        NSPoint pt = [CCBDictionaryReader deserializePoint:serializedValue];
		
        [node setValue:[NSValue valueWithPoint:pt] forKey:name];
    }
    else if ([type isEqualToString:@"Size"])
    {
        CCSizeType sizeType = CCSizeTypePoints;
        NSSize size = [self deserializeSize:serializedValue sizeType:&sizeType];

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
        [node setValue:@(x) forKey:[name stringByAppendingString:@"X"]];
        [node setValue:@(y) forKey:[name stringByAppendingString:@"Y"]];
    }
    else if ([type isEqualToString:@"Float"]
             || [type isEqualToString:@"Degrees"])
    {
        float f = [CCBDictionaryReader deserializeFloat:serializedValue];
        [node setValue:@(f) forKey:name];
    }
    else if ([type isEqualToString:@"FloatCheck"] || [type isEqualToString:@"EnabledFloat"] )
    {
        float f = [[serializedValue objectAtIndex:0] floatValue];
        BOOL enabled = [[serializedValue objectAtIndex:1] boolValue];

        [node setValue:@(enabled) forKey:[NSString stringWithFormat:@"%@Enabled", name]];
        [node setValue:@(f) forKey:name];

    }
    else if ([type isEqualToString:@"FloatScale"])
    {
        float f = 0;
        int aType = 0;
        if ([serializedValue isKindOfClass:[NSNumber class]])
        {
            // Support for old files
            f = [serializedValue floatValue];
        }
        else
        {
            f = [[serializedValue objectAtIndex:0] floatValue];
            aType = [[serializedValue objectAtIndex:1] intValue];
        }
        [PositionPropertySetter setFloatScale:f type:aType forNode:node prop:name];
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
        int d = [CCBDictionaryReader deserializeInt:serializedValue];
        [node setValue:@(d) forKey:name];
    }
    else if ([type isEqualToString:@"Check"])
    {
        BOOL check = [CCBDictionaryReader deserializeBool:serializedValue];
        [node setValue:@(check) forKey:name];
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
        
        extraProps[[NSString stringWithFormat:@"%@Sheet", name]] = spriteSheetFile;
        extraProps[name] = spriteFile;
        [TexturePropertySetter setSpriteFrameForNode:node andProperty:name withFile:spriteFile andSheetFile:spriteSheetFile];
    }
    else if ([type isEqualToString:@"Texture"])
    {
        NSString* spriteFile = serializedValue;
        if (!spriteFile) spriteFile = @"";
        [TexturePropertySetter setTextureForNode:node andProperty:name withFile:spriteFile];
        extraProps[name] = spriteFile;
    }
    else if ([type isEqualToString:@"Color4"] ||
             [type isEqualToString:@"Color3"])
    {
        CCColor* colorValue = [CCBDictionaryReader deserializeColor4:serializedValue];
        [node setValue:colorValue forKey:name];
    }
    else if ([type isEqualToString:@"Color4FVar"])
    {
        CCColor* cValue = [CCBDictionaryReader deserializeColor4:[serializedValue objectAtIndex:0]];
        CCColor* cVarValue = [CCBDictionaryReader deserializeColor4:[serializedValue objectAtIndex:1]];
        [node setValue:cValue forKey:name];
        [node setValue:cVarValue forKey:[NSString stringWithFormat:@"%@Var",name]];
    }
    else if ([type isEqualToString:@"Blendmode"])
    {
        CCBlendMode *blendMode = [CCBDictionaryReader deserializeBlendMode:serializedValue];
        [node setValue:blendMode forKey:name];
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
        if (!target) target = @0;
		

		//Fixup blocks so if target = NOne, set string = @"" and target = 1;
		if([target integerValue] == 0)
		{
			selector = @"";
			target = @(1);
		}
		
        extraProps[name] = selector;
        extraProps[[NSString stringWithFormat:@"%@Target", name]] = target;
    }
    else if ([type isEqualToString:@"BlockCCControl"])
    {
        NSString* selector = [serializedValue objectAtIndex:0];
        NSNumber* target = [serializedValue objectAtIndex:1];
        NSNumber* ctrlEvts = [serializedValue objectAtIndex:2];
        if (!selector) selector = @"";
        if (!target) target = @0;
        if (!ctrlEvts) ctrlEvts = @0;
        extraProps[name] = selector;
        extraProps[[NSString stringWithFormat:@"%@Target", name]] = target;
        extraProps[[NSString stringWithFormat:@"%@CtrlEvts", name]] = ctrlEvts;
    }
    else if ([type isEqualToString:@"CCBFile"])
    {
        NSString* ccbFile = serializedValue;
        if (!ccbFile) ccbFile = @"";
        [NodeGraphPropertySetter setNodeGraphForNode:node andProperty:name withFile:ccbFile parentSize:parentSize];
        extraProps[name] = ccbFile;
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
	else if([type isEqualToString:@"EffectControl"])
	{
		CCNode<CCEffectNodeProtocol> *effectNode = (CCNode<CCEffectNodeProtocol> *)node;
		
		NSMutableArray * effects = [NSMutableArray new];
		
		for (NSDictionary * serializedEffect in serializedValue) {
			NSString* className = serializedEffect[@"className"];
			id serializedProperties = serializedEffect[@"properties"];
			
			EffectDescription * effectDescription = [EffectsManager effectByClassName:className];
			
			if(!effectDescription)
			{
				NSLog(@"ERROR: Failed to find effect class of type : %@ in EffectManager description", className);
				return;
			}
			
			NSObject<EffectProtocol> *effect = (id<EffectProtocol>)[effectDescription constructDefault];
			
			[effect deserialize:serializedProperties];
			effect.UUID = [serializedEffect[@"UUID"] unsignedIntegerValue];
			
			
			[effects addObject:effect];
		}
		
		effectNode.effects = effects;
	}
    else if([type isEqualToString:@"TokenArray"])
    {
        [node setValue:serializedValue forKey:name];
    }
    else
    {
        NSLog(@"WARNING Unrecognized property type: %@", type);
    }
}

+ (CCBlendMode *)deserializeBlendMode:(id)value
{
    return [CCBlendMode blendModeWithOptions:value];
}

+ (CCNode *)nodeGraphFromNodeGraphData:(NSDictionary *)nodeGraphData parentSize:(CGSize)parentSize withParentGraph:(CCNode *)parentGraph;
{
    if (!renamedProperties)
    {
        renamedProperties = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CCBDictionaryReaderRenamedProps" ofType:@"plist"]];
        NSAssert(renamedProperties, @"Failed to load renamed properties dict");
    }
    
    NSArray* props = nodeGraphData[@"properties"];
    NSString* baseClass = nodeGraphData[@"baseClass"];
    NSArray* children = nodeGraphData[@"children"];
    
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
    node.UUID = [nodeGraphData[@"UUID"] unsignedIntegerValue];
    
    // Flash skew compatibility
    if ([nodeGraphData[@"usesFlashSkew"] boolValue])
    {
        [node setUsesFlashSkew:YES];
    }
    
    // Hidden node graph
    if ([nodeGraphData[@"hidden"] boolValue])
    {
        node.hidden = YES;
    }
    
    // Locked node
    if ([nodeGraphData[@"locked"] boolValue])
    {
        node.locked = YES;
    }
    
    // Set properties for the node
    int numProps = (int) [props count];
    for (int i = 0; i < numProps; i++)
    {
        NSDictionary* propInfo = props[(NSUInteger) i];
        NSString* type = propInfo[@"type"];
        NSString* name = propInfo[@"name"];
        id serializedValue = propInfo[@"value"];
        
        // Check for renamings
        NSDictionary* renameRule = renamedProperties[name];
        if (renameRule)
        {
            name = renameRule[@"newName"];
        }
        
        if ([plugIn dontSetInEditorProperty:name])
        {
            extraProps[name] = serializedValue;
        }
        else
        {
            [CCBDictionaryReader setProp:name ofType:type toValue:serializedValue forNode:node parentSize:parentSize withParentGraph:parentGraph];
        }
        id baseValue = propInfo[@"baseValue"];
        if (baseValue) [node setBaseValue:baseValue forProperty:name];
    }
    
    // Set extra properties for code connections
    NSString* customClass = nodeGraphData[@"customClass"];
    if (!customClass) customClass = @"";
    NSString* memberVarName = nodeGraphData[@"memberVarAssignmentName"];
    if (!memberVarName) memberVarName = @"";
    int memberVarType = [nodeGraphData[@"memberVarAssignmentType"] intValue];
    
    //memberVarType is obsolete. Set to 1 upon deserialization.
    if(memberVarType == 0)
    {
        memberVarType = 1;
        memberVarName = @""; //Make sure we clear the name, since it was unassigned.
    }
    
    extraProps[@"customClass"] = customClass;
    extraProps[@"memberVarAssignmentName"] = memberVarName;
    extraProps[@"memberVarAssignmentType"] = @(memberVarType);
    
    // JS code connections
    NSString* jsController = nodeGraphData[@"jsController"];
    if (jsController)
    {
        extraProps[@"jsController"] = jsController;
    }
    
    NSString* displayName = nodeGraphData[@"displayName"];
    if (displayName)
    {
        node.displayName = displayName;
    }
    
    id animatedProps = nodeGraphData[@"animatedProperties"];
    [node loadAnimatedPropertiesFromSerialization:animatedProps];
    node.seqExpanded = [nodeGraphData[@"seqExpanded"] boolValue];
    
    CGSize contentSize = node.contentSize;
    for (NSUInteger i = 0; i < [children count]; i++)
    {
        CCNode* child = [CCBDictionaryReader nodeGraphFromNodeGraphData:children[i] parentSize:contentSize withParentGraph:nil];
		
		if (child)
		{
			[node addChild:child z:i];
		}
    }
    
    // Physics
    if (nodeGraphData[@"physicsBody"])
    {
        node.nodePhysicsBody = [[NodePhysicsBody alloc] initWithSerialization:nodeGraphData[@"physicsBody"]];
    }
    
    // Selections
    if ([nodeGraphData[@"selected"] boolValue])
    {
        [[AppDelegate appDelegate].loadedSelectedNodes addObject:node];
    }
    
    BOOL isCCBSubFile = [baseClass isEqualToString:@"CCBFile"];
    
    // Load custom properties
    if (isCCBSubFile)
    {
        // For sub ccb files the custom properties are already loaded by the sub file and forwarded. We just need to override the values from the sub ccb file
        [node loadCustomPropertyValuesFromSerialization:nodeGraphData[@"customProperties"]];
    }
    else
    {
        [node loadCustomPropertiesFromSerialization:nodeGraphData[@"customProperties"]];
    }
    
    return node;
}

+ (CCNode *)nodeGraphFromDocumentData:(NSDictionary *)documentData parentSize:(CGSize)parentSize error:(NSError **)error
{
    if (!documentData)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBCCBReadingError message:@"Document is nil"];
        return nil;
    }

    if (![self isFileVersionValid:[documentData[CCB_DICTIONARY_KEY_FILEVERSION] intValue] error:error])
    {
        return nil;
    }

    if (![self isFileTypeValid:documentData[CCB_DICTIONARY_KEY_FILETYPE] error:error])
    {
        return nil;
    }

    NSDictionary *nodeGraph = documentData[CCB_DICTIONARY_KEY_NODEGRAPH];
    CCNode *node = [CCBDictionaryReader nodeGraphFromNodeGraphData:nodeGraph parentSize:parentSize withParentGraph:nil];
    if (node)
    {
        return node;
    }

    [NSError setNewErrorWithErrorPointer:error code:SBCCBReadingErrorNoNodesFound message:@"No nodes found"];
    return nil;
}

+ (BOOL)isFileTypeValid:(NSString *)fileType error:(NSError **)error
{
    if (!fileType
        || !([fileType isEqualToString:@"CocosBuilder"]
             || [fileType isEqualToString:@"SpriteBuilder"]))
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBCCBReadingErrorInvalidFileType
                                     message:[NSString stringWithFormat:@"Filetype is wrong: Should be CocosBuilder but \"%@\" found", fileType]];
        return NO;
    }
    return YES;
}

+ (BOOL)isFileVersionValid:(int)fileVersion error:(NSError **)error
{
    if (fileVersion <= kCCBDictionaryLowestVersionSupport)
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBCCBReadingErrorVersionTooOld
                                     message:[NSString stringWithFormat:@"Version no longer supported, min version is %d but %d found", kCCBDictionaryLowestVersionSupport, fileVersion]];
        return NO;
    }
    else if (fileVersion > kCCBDictionaryFormatVersion)
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBCCBReadingErrorVersionHigherThanSpritebuilderSupport
                                     message:[NSString stringWithFormat:@"Version is newer than version supported by Spritebuilder, version found %d, support %d", fileVersion, kCCBDictionaryFormatVersion]];
        return NO;
    }
    return YES;
}

+(void)postDeserializationFixup:(CCNode*)node
{
	if([node respondsToSelector:@selector(postDeserializationFixup)])
	{
		[node performSelector:@selector(postDeserializationFixup) withObject:nil];
	}
	
	for(CCNode * child in node.children)
	{
		[self postDeserializationFixup:child];
	}
}

@end
