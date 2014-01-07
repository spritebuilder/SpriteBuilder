//
//  PropertyInspectorTemplate.m
//  CocosBuilder
//
//  Created by Viktor on 7/30/13.
//
//

#import "PropertyInspectorTemplate.h"
#import "CCNode+NodeInfo.h"
#import "PlugInNode.h"
#import "HashValue.h"
#import "CCBWriterInternal.h"
#import "CCBReaderInternal.h"

@implementation PropertyInspectorTemplate

- (id) initWithNode:(CCNode*)node name:(NSString*)n bgColor:(NSColor*)c
{
    self = [super init];
    if (!self) return NULL;
    
    c = [c colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    
    self.name = n;
    self.color = c;
    
    PlugInNode* plugIn = node.plugIn;
    
    NSString* className = plugIn.nodeClassName;
    self.nodeType = className;
    
    // Generate image
    [self savePreviewForNode:node size:CGSizeMake(256,256) bgColor:c toFile:[self imgFileNamePath]];
    self.image = [[NSImage alloc] initWithContentsOfFile:[self imgFileNamePath]];
    
    // Save properties
    NSMutableArray* props = [NSMutableArray array];
    
    NSArray* plugInProps = plugIn.nodeProperties;
    
    for (NSMutableDictionary* propInfo in plugInProps)
    {
        if ([[propInfo objectForKey:@"saveInTemplate"] boolValue])
        {
            id serializedValue = [CCBWriterInternal serializePropertyForNode:node propInfo:propInfo excludeProps:NULL];
            
            NSMutableDictionary* serProp = [NSMutableDictionary dictionary];
            [serProp setObject:serializedValue forKey:@"value"];
            [serProp setObject:[propInfo objectForKey:@"type"] forKey:@"type"];
            [serProp setObject:[propInfo objectForKey:@"name"] forKey:@"name"];
            
            if (serializedValue)
            {
                [props addObject:serProp];
            }
            else
            {
                NSLog(@"WARNING! Failed to serialize value: %@", propInfo);
            }
        }
    }
    
    self.properties = props;
    
    return self;
}

- (void) applyToNode:(CCNode*) node
{
    for (id propInfo in self.properties)
    {
        NSString* type = [propInfo objectForKey:@"type"];
        NSString* name = [propInfo objectForKey:@"name"];
        id serializedValue = [propInfo objectForKey:@"value"];
        
        [CCBReaderInternal setProp:name ofType:type toValue:serializedValue forNode:node parentSize:CGSizeMake(0, 0)];
    }
}

- (id) initWithSerialization:(NSDictionary*) dict
{
    self = [super init];
    if (!self) return NULL;
    
    NSArray* c = [dict objectForKey:@"color"];
    float r = [[c objectAtIndex:0] floatValue];
    float g = [[c objectAtIndex:1] floatValue];
    float b = [[c objectAtIndex:2] floatValue];
    NSColor* color = [NSColor colorWithDeviceRed:r green:g blue:b alpha:1];
    
    self.name = [dict objectForKey:@"name"];
    self.color = color;
    self.nodeType = [dict objectForKey:@"nodeType"];
    
    self.image = [[NSImage alloc] initWithContentsOfFile:[self imgFileNamePath]];
    
    self.properties = [dict objectForKey:@"properties"];
    
    return self;
}

- (id) serialization
{
    NSMutableDictionary* ser = [NSMutableDictionary dictionary];
    
    CGFloat r, g, b, a;
    [self.color getRed:&r green:&g blue:&b alpha:&a];
    NSArray* c = [NSArray arrayWithObjects:
                  [NSNumber numberWithFloat:r],
                  [NSNumber numberWithFloat:g],
                  [NSNumber numberWithFloat:b],
                  nil];
    
    [ser setObject:self.name forKey:@"name"];
    [ser setObject:c forKey:@"color"];
    [ser setObject:self.nodeType forKey:@"nodeType"];
    
    if (self.properties)
    {
        [ser setObject:self.properties forKey:@"properties"];
    }
    
    return ser;
}

- (NSString*) imgFileNamePath
{
    HashValue* hash = [HashValue md5HashWithString:[NSString stringWithFormat:@"%@:%@", self.nodeType, self.name]];
    return [[[PropertyInspectorTemplateLibrary templateDirectory] stringByAppendingPathComponent:[hash description]] stringByAppendingPathExtension:@"png"];
}

- (void) savePreviewForNode:(CCNode*) node size:(CGSize)size bgColor:(NSColor*)bgColor toFile:(NSString*)path
{
    // Remember old position of root node
    CGPoint oldPosition = node.position;
    CCNode* parent = node.parent;
    NSInteger oldZOrder = node.zOrder;
    [parent removeChild:node cleanup:NO];
    
    // Create render context
    CCRenderTexture* render = [CCRenderTexture renderTextureWithWidth:size.width height:size.height];
    
    // Create background color layer
    CGFloat r, g, b, a;
    [bgColor getRed:&r green:&g blue:&b alpha:&a];
    CCColor* c = [CCColor colorWithRed:r green:g blue:b alpha:a];
    CCNodeColor* bgLayer = [CCNodeColor nodeWithColor:c width:size.width height:size.height];
    
    // Add node to bg
    [bgLayer addChild:node];
    
    node.position = ccp(size.width/2, size.height/2);
    
    // Render the root node
    [render beginWithClear:0 g:0 b:0 a:255];
    [bgLayer visit];
    [render end];
    
    CGImageRef imgRef = [render newCGImage];
    
    // Save preview file
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
	CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
	CGImageDestinationAddImage(dest, imgRef, nil);
	CGImageDestinationFinalize(dest);
	CFRelease(dest);
    
    // Release image
    CGImageRelease(imgRef);
    
    // Reset old position
    node.position = oldPosition;
    [bgLayer removeChild:node cleanup:NO];
    [parent addChild:node z:oldZOrder];
}


@end

@implementation PropertyInspectorTemplateLibrary

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    library = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void) loadLibrary
{
    [library removeAllObjects];
    
    // Load from file
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:[[PropertyInspectorTemplateLibrary templateDirectory] stringByAppendingPathComponent:@"templates.plist"]];
    if (dict)
    {
        for (NSString* nodeType in dict)
        {
            NSArray* serTemplates = [dict objectForKey:nodeType];
            NSMutableArray* templates = [NSMutableArray array];
            
            for (NSDictionary* serTempl in serTemplates)
            {
                PropertyInspectorTemplate* templ = [[PropertyInspectorTemplate alloc] initWithSerialization:serTempl];
                [templates addObject:templ];
            }
            
            [library setObject:templates forKey:nodeType];
        }
    }
}


- (BOOL) hasTemplateForNodeType:(NSString*)type andName:(NSString*)name
{
    NSArray* templates = [self templatesForNodeType:type];
    for (PropertyInspectorTemplate* templ in templates)
    {
        if ([[templ.name lowercaseString] isEqualToString:[name lowercaseString]]) return YES;
    }
    return NO;
}

- (void) addTemplate:(PropertyInspectorTemplate*)templ
{
    NSMutableArray* templates = [library objectForKey:templ.nodeType];
    if (!templates)
    {
        templates = [NSMutableArray array];
        [library setObject:templates forKey:templ.nodeType];
    }
    
    [templates addObject:templ];
    
    [self store];
}

- (void) removeTemplate:(PropertyInspectorTemplate*)templ
{
    NSMutableArray* templates = [library objectForKey:templ.nodeType];
    if (templates)
    {
        for (PropertyInspectorTemplate* templCheck in templates)
        {
            if (templCheck == templ)
            {
                // Remove preview image
                NSFileManager* fm = [NSFileManager defaultManager];
                [fm removeItemAtPath:[templ imgFileNamePath] error:NULL];
                break;
            }
        }
        
        [templates removeObject:templ];
    }
    
    [self store];
}

- (NSArray*) templatesForNodeType:(NSString*) nodeType
{
    NSArray* templates = [library objectForKey:nodeType];
    if (templates) return templates;
    return [NSArray array];
}

+ (NSString*) templateDirectory
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Find application support directory for CocosBuilder
    NSError *error;
    NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    appSupportDir = [appSupportDir URLByAppendingPathComponent:@"com.cocosbuilder"];
    
    // Create directory for templates if it doesn't exist
    NSURL* templDir = [appSupportDir URLByAppendingPathComponent:@"templates"];
    [fm createDirectoryAtURL:templDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    
    return templDir.path;
}

- (void) store
{
    NSMutableDictionary* ser = [NSMutableDictionary dictionary];
    
    for (NSString* nodeType in library)
    {
        NSMutableArray* serTemplates = [NSMutableArray array];
        
        NSArray* templates = [self templatesForNodeType:nodeType];
        
        for (PropertyInspectorTemplate* templ in templates)
        {
            [serTemplates addObject:[templ serialization]];
        }
        
        [ser setObject:serTemplates forKey:nodeType];
    }
    
    [ser writeToFile:[[PropertyInspectorTemplateLibrary templateDirectory] stringByAppendingPathComponent:@"templates.plist"] atomically:YES];
}

@end
