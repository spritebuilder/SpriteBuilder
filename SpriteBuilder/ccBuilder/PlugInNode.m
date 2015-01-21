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

#import "PlugInNode.h"
#import "AppDelegate.h"
#import "CCNode+NodeInfo.h"
#import "SBPasteboardTypes.h"


@interface PlugInNode()

@property (nonatomic, strong) NSBundle *mainBundle;

@end


@implementation PlugInNode

@synthesize nodeClassName;
@synthesize nodeEditorClassName;
@synthesize displayName;
@synthesize descr;
@synthesize ordering;
@synthesize supportsTemplates;
@synthesize nodeProperties;
@synthesize nodePropertiesDict;
@synthesize dropTargetSpriteFrameClass;
@synthesize dropTargetSpriteFrameProperty;
@synthesize canBeRoot;
@synthesize canHaveChildren;
@synthesize isAbstract;
@synthesize isJoint;
@synthesize requireParentClass;
@synthesize requireChildClass;
@synthesize icon;

- (void) loadPropertiesForBundle:(NSBundle*)aBundle intoArray:(NSMutableArray*)array
{
    NSURL* propsURL = [aBundle URLForResource:@"CCBPProperties" withExtension:@"plist"];
    NSMutableDictionary*properties = [NSMutableDictionary dictionaryWithContentsOfURL:propsURL];
    
    [self addProperitesFromSuperClassToArray:array props:properties];

    [array addObjectsFromArray:properties[@"properties"]];

    [self overridePropertiesInArray:array props:properties];
}

- (void)addProperitesFromSuperClassToArray:(NSMutableArray *)array props:(NSMutableDictionary *)props
{
    NSString* inheritsFrom = props[@"inheritsFrom"];
    if (inheritsFrom)
    {
        NSURL* plugInDir = [_mainBundle builtInPlugInsURL];

        NSURL* superBundleURL = [plugInDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.ccbPlugNode",inheritsFrom]];

        NSBundle* superBundle = [NSBundle bundleWithURL:superBundleURL];

        [self loadPropertiesForBundle:superBundle intoArray:array];
    }
}

- (void)overridePropertiesInArray:(NSMutableArray *)array props:(NSMutableDictionary *)props
{
    NSArray *propertiesToOverride = props[@"propertiesOverridden"];
    for (NSDictionary *propertyToOverride in propertiesToOverride)
    {
        NSString* propName = propertyToOverride[@"name"];
        BOOL shouldBeRemoved = [propertyToOverride[@"type"] isEqualToString:@"None"];

        // Find the old property
        for (int oldPropIdx = [array count] - 1; oldPropIdx >= 0; oldPropIdx--)
        {
            NSDictionary* oldPropInfo = array[(NSUInteger) oldPropIdx];
            if ([oldPropInfo[@"name"] isEqualToString:propName])
            {
                if (shouldBeRemoved)
                {
                    [array removeObjectAtIndex:(NSUInteger) oldPropIdx];
                }
                else
                {
                    array[(NSUInteger) oldPropIdx] = propertyToOverride;
                }
            }
        }
    }
}

- (void) setupNodePropsDict
{
    // Transform the nodes info array to a dictionary for quicker lookups of properties
    for (NSUInteger i = 0; i < [nodeProperties count]; i++)
    {
        NSDictionary* propInfo = nodeProperties[i];
        
        NSString* propName = propInfo[@"name"];
        if (propName)
        {
            nodePropertiesDict[propName] = propInfo;
        }
    }
}

- (id)initWithBundle:(NSBundle *)aBundle mainBundle:(NSBundle *)mainBundle
{
    NSAssert(aBundle != nil, @"bundle must not be nil");
    NSAssert(mainBundle != nil, @"mainBundle must not be nil");

    self = [super init];
    if (!self)
    {
        return NULL;
    }

    bundle = aBundle;
    self.mainBundle = mainBundle;

    // Load properties
    NSURL* propsURL = [bundle URLForResource:@"CCBPProperties" withExtension:@"plist"];
    NSMutableDictionary* props = [NSMutableDictionary dictionaryWithContentsOfURL:propsURL];
    
	_targetEngine = CCBTargetEngineCocos2d;

    nodeClassName = props[@"className"];
    nodeEditorClassName = props[@"editorClassName"];
    
    displayName = props[@"displayName"];
    descr = props[@"description"];
    ordering = [props[@"ordering"] intValue];
    supportsTemplates = [props[@"supportsTemplates"] boolValue];
    
    if (!displayName) displayName = [nodeClassName copy];
    if (!ordering) ordering = 100000;
    if (!descr) descr = [@"" copy];
    
    nodeProperties = [[NSMutableArray alloc] init];
    nodePropertiesDict = [[NSMutableDictionary alloc] init];
    [self loadPropertiesForBundle:bundle intoArray:nodeProperties];
    [self setupNodePropsDict];
    
    // Support for spriteFrame drop targets
    NSDictionary* spriteFrameDrop = props[@"spriteFrameDrop"];
    if (spriteFrameDrop)
    {
        dropTargetSpriteFrameClass = spriteFrameDrop[@"className"];
        dropTargetSpriteFrameProperty = spriteFrameDrop[@"property"];
        
    }
    
    // Check if node type can be root node and which children are allowed
    canBeRoot = [props[@"canBeRootNode"] boolValue];
    canHaveChildren = [props[@"canHaveChildren"] boolValue];
    isAbstract = [props[@"isAbstract"] boolValue];
    isJoint = [props[@"isJoint"] boolValue];
    requireChildClass = props[@"requireChildClass"];
    requireParentClass = props[@"requireParentClass"];
    positionProperty = props[@"positionProperty"];
    
    return self;
}

- (BOOL) acceptsDroppedSpriteFrameChildren
{
    return dropTargetSpriteFrameClass && dropTargetSpriteFrameProperty;
}

- (BOOL) dontSetInEditorProperty: (NSString*) prop
{
    NSDictionary* propInfo = nodePropertiesDict[prop];
    BOOL dontSetInEditor = [propInfo[@"dontSetInEditor"] boolValue];
    if ([propInfo[@"type"] isEqualToString:@"Separator"]
        || [propInfo[@"type"] isEqualToString:@"SeparatorSub"])
    {
        dontSetInEditor = YES;
    }
    
    return dontSetInEditor;
}

- (NSString*) positionProperty
{
    if (positionProperty) return positionProperty;
    return @"position";
}

- (NSArray*) readablePropertiesForType:(NSString*)type node:(CCNode*)node
{
    BOOL useFlashSkew = [node usesFlashSkew];
    
    NSMutableArray* props = [NSMutableArray array];
    for (NSDictionary* propInfo in nodeProperties)
    {
        if (useFlashSkew && [propInfo[@"name"] isEqualToString:@"rotation"]) continue;
        if (!useFlashSkew && [propInfo[@"name"] isEqualToString:@"rotationalSkewX"]) continue;
        if (!useFlashSkew && [propInfo[@"name"] isEqualToString:@"rotationalSkewY"]) continue;
        
        if ([propInfo[@"type"] isEqualToString:type] && ![propInfo[@"readOnly"] boolValue])
        {
            [props addObject:propInfo[@"name"]];
        }
    }
    return props;
}

- (NSArray*) animatablePropertiesForNode:(CCNode*)node
{
    BOOL useFlashSkew = [node usesFlashSkew];
    
    if (!useFlashSkew && cachedAnimatableProperties) return cachedAnimatableProperties;
    if (useFlashSkew && cachedAnimatablePropertiesFlashSkew) return cachedAnimatablePropertiesFlashSkew;
    
    NSMutableArray* props = [NSMutableArray array];
    
    for (NSDictionary* propInfo in nodeProperties)
    {
        if (useFlashSkew && [propInfo[@"name"] isEqualToString:@"rotation"]) continue;
        if (!useFlashSkew && [propInfo[@"name"] isEqualToString:@"rotationalSkewX"]) continue;
        if (!useFlashSkew && [propInfo[@"name"] isEqualToString:@"rotationalSkewY"]) continue;
        
        if ([propInfo[@"animatable"] boolValue])
        {
            [props addObject:propInfo[@"name"]];
        }
    }
    
    if (!useFlashSkew) cachedAnimatableProperties = props;
    else cachedAnimatablePropertiesFlashSkew = props;
    
    return props;
}

- (BOOL) isAnimatableProperty:(NSString*)prop node:(CCNode*)node
{
    for (NSString* animProp in [self animatablePropertiesForNode:node])
    {
        if ([animProp isEqualToString:prop])
        {
            return YES;
        }
    }
    return NO;
}

- (NSString*) propertyTypeForProperty:(NSString*)property
{
    return [nodePropertiesDict[property] objectForKey:@"type"];
}

#pragma mark Drag and Drop

- (id) pasteboardPropertyListForType:(NSString *)pbType
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    if ([pbType isEqualToString:PASTEBOARD_TYPE_PLUGINNODE])
    {
        dict[@"nodeClassName"] = self.nodeClassName;
        return dict;
    }
    return NULL;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableArray* pbTypes = [@[PASTEBOARD_TYPE_PLUGINNODE] mutableCopy];
    return pbTypes;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)pbType pasteboard:(NSPasteboard *)pasteboard
{
    if ([pbType isEqualToString:PASTEBOARD_TYPE_PLUGINNODE]) return NSPasteboardWritingPromised;
    return 0;
}

#pragma mark Deallocation

-(void) dealloc
{
    #ifndef TESTING
	SBLogSelf();
    #endif
}

-(NSString*) description
{
	return [NSString stringWithFormat:@"%@ name=%@ class=%@ editorClass=%@", [super description], displayName, nodeClassName, nodeEditorClassName];
}

@end
