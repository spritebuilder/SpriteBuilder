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
    
    // TODO: Generate image
    [self savePreviewForNode:node size:CGSizeMake(256,256) bgColor:c toFile:@"/Users/Lidholt/Desktop/foo.png"];
    
    return self;
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
    ccColor4B c = ccc4(r*255, g*255, b*255, 255);
    CCLayerColor* bgLayer = [CCLayerColor layerWithColor:c width:size.width height:size.height];
    
    // Add node to bg
    [bgLayer addChild:node];
    
    NSLog(@"r: %f g: %f b: %f", r, g, b);
    
    node.position = ccp(size.width/2, size.height/2);
    
    // Render the root node
    //[render beginWithClear:r*255 g:g*255 b:b*255 a:255];
    [render beginWithClear:0 g:0 b:0 a:255];
    [bgLayer visit];
    [render end];
    
    CGImageRef imgRef = [render newCGImage];
    
    // Save preview file
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
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

- (void) dealloc
{
    self.name = NULL;
    self.image = NULL;
    self.nodeType = NULL;
    self.color = NULL;
    [super dealloc];
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

- (void) dealloc
{
    [library release];
    [super dealloc];
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
}

- (NSArray*) templatesForNodeType:(NSString*) nodeType
{
    NSArray* templates = [library objectForKey:nodeType];
    if (templates) return templates;
    return [NSArray array];
}

@end
