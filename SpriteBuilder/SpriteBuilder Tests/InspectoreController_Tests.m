//
//  InspectoreController_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 10.10.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "AppDelegate.h"
#import "InspectorController.h"
#import "PropertyInspectorHandler.h"
#import "CocosScene.h"
#import "SequencerHandler.h"
#import "PlugInManager.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "SBAssserts.h"

@interface InspectoreController_Tests : XCTestCase

@property (nonatomic, strong) InspectorController *inspectorController;
@property (nonatomic, strong) NSScrollView *inspectorScroll;
@property (nonatomic, strong) NSScrollView *inspectoreCodeScroll;
@property (nonatomic, strong) NSView *inspectorPhysics;
@property (nonatomic, strong) id propertyInspectorHandler;
@property (nonatomic, strong) id cocosScene;
@property (nonatomic, strong) id sequenceHandler;
@property (nonatomic, strong) id appDelegate;

@end


@implementation InspectoreController_Tests

- (void)setUp
{
    [super setUp];

    [AppDelegate class];

    self.inspectorController = [[InspectorController alloc] init];
    self.inspectorScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
    self.inspectoreCodeScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
    self.inspectorPhysics = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 100.0)];
    self.propertyInspectorHandler = [OCMockObject niceMockForClass:[PropertyInspectorHandler class]];
    self.cocosScene = [OCMockObject niceMockForClass:[CocosScene class]];
    self.sequenceHandler = [OCMockObject niceMockForClass:[SequencerHandler class]];
    self.appDelegate = [OCMockObject niceMockForClass:[AppDelegate class]];

    _inspectorController.inspectorScroll = _inspectorScroll;
    _inspectorController.inspectorCodeScroll = _inspectoreCodeScroll;
    _inspectorController.inspectorPhysics = _inspectorPhysics;
    _inspectorController.propertyInspectorHandler = _propertyInspectorHandler;
    _inspectorController.cocosScene = _cocosScene;
    _inspectorController.sequenceHandler = _sequenceHandler;
    _inspectorController.appDelegate = _appDelegate;
}

- (void)testSetupInspectorController
{
    [_inspectorController setupInspectorPane];

    XCTAssertNotNil(_inspectorScroll.documentView);
    XCTAssertNotNil(_inspectoreCodeScroll.documentView);
}


- (void)testUpdateInspectorFromSelectionForCCNode
{
    [self testUpdateInspectorFromSelectionForPlugin:@"CCNode"
                             withExpectedProperties:@[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew"]
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCColorNode
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew", @"color", @"opacity", @"blendFunc"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCNodeColor"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCBFile
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew", @"ccbFile"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCBFile"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCEffectNode
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew", @"effects"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCEffectNode"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCGradientNode
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew",
            @"startColor", @"startOpacity", @"endColor", @"endOpacity", @"blendFunc", @"vector"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCNodeGradient"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCSprite
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew",
            @"spriteFrame", @"normalMapSpriteFrame", @"opacity", @"color", @"flip", @"blendFunc", @"effects"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCSprite"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCParticleSystem
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew",
            @"emitterMode", @"posVar", @"emissionRate", @"duration", @"totalParticles", @"life", @"startSize", @"endSize", @"startSpin",
            @"endSpin", @"angle", @"startColor", @"endColor", @"blendFunc", @"resetOnVisibilityToggle", @"gravity", @"speed", @"tangentialAccel",
            @"radialAccel", @"startRadius", @"endRadius", @"rotatePerSecond", @"texture"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCParticleSystem"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCLabelTTF
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew",
            @"string", @"fontName", @"fontSize", @"adjustsFontSizeToFit", @"opacity", @"color", @"dimensions", @"horizontalAlignment",
            @"verticalAlignment", @"fontColor", @"outlineColor", @"outlineWidth", @"shadowColor", @"shadowBlurRadius", @"shadowOffset"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCLabelTTF"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCLabelBMFont
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew",
            @"fntFile", @"opacity", @"color", @"blendFunc", @"string"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCLabelBMFont"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCButton
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation",
            @"skew", @"CCControl", @"CCControl", @"preferredSize",
            @"maxSize", @"userInteractionEnabled", @"CCButton", @"title", @"zoomWhenHighlighted", @"togglesSelectedState",
            @"onSetSizeFromTexture", @"Normal State", @"backgroundSpriteFrame|Normal", @"backgroundOpacity|Normal",
            @"backgroundColor|Normal", @"labelOpacity|Normal", @"labelColor|Normal",
            @"Highlighted State", @"backgroundSpriteFrame|Highlighted", @"backgroundOpacity|Highlighted",
            @"backgroundColor|Highlighted", @"labelOpacity|Highlighted", @"labelColor|Highlighted", @"Disabled State",
            @"backgroundSpriteFrame|Disabled", @"backgroundOpacity|Disabled", @"backgroundColor|Disabled", @"labelOpacity|Disabled",
            @"labelColor|Disabled", @"Selected State", @"backgroundSpriteFrame|Selected", @"backgroundOpacity|Selected", @"backgroundColor|Selected",
            @"labelOpacity|Selected", @"labelColor|Selected", @"CCLabelTTF", @"fontName", @"fontSize", @"horizontalAlignment",
            @"verticalAlignment", @"horizontalPadding", @"verticalPadding", @"Font Effects", @"fontColor", @"outlineColor",
            @"outlineWidth", @"shadowColor", @"shadowBlurRadius", @"shadowOffset"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCButton"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass", @"block", @"continuous"]];
}

- (void)testUpdateInspectorFromSelectionForCCTextField
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation",
            @"skew", @"CCControl",  @"CCControl", @"preferredSize", @"maxSize", @"userInteractionEnabled",
            @"backgroundSpriteFrame", @"padding", @"fontSize"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCTextField"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass", @"block", @"continuous"]];
}

- (void)testUpdateInspectorFromSelectionForCCSlider
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew",
            @"CCControl", @"preferredSize", @"maxSize", @"userInteractionEnabled", @"backgroundSpriteFrame|Normal",
            @"handleSpriteFrame|Normal", @"Highlighted state", @"backgroundSpriteFrame|Highlighted", @"handleSpriteFrame|Highlighted",
            @"Disabled state", @"backgroundSpriteFrame|Disabled", @"handleSpriteFrame|Disabled"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCSlider"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass", @"block", @"continuous"]];
}

- (void)testUpdateInspectorFromSelectionForCCScrollView
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew", @"contentNode", @"horizontalScrollEnabled",
            @"verticalScrollEnabled", @"bounces", @"pagingEnabled"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCScrollView"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

- (void)testUpdateInspectorFromSelectionForCCLayoutBox
{
    NSArray *properties = @[@"visible", @"name", @"position", @"contentSize", @"anchorPoint", @"scale", @"rotation", @"skew", @"direction", @"spacing"];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCLayoutBox"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}

/*
- (void)testUpdateInspectorFromSelectionForCCPhyicsNode
{
    NSArray *properties = @[];

    [self testUpdateInspectorFromSelectionForPlugin:@"CCLayoutBox"
                             withExpectedProperties:properties
                                    codeConnections:@[@"customClass"]];
}
*/

- (void)testRefreshPropertyForName
{
    CCNode *node = [self setupInspectorAndSelectedNodeWithPlugin:@"CCNode"];
    node.name = @"123456";

    [_inspectorController updateInspectorFromSelection];

    NSView *inspectorView = [self viewWithIdentifier:@"TestInspector_name" inView:_inspectorScroll.documentView];
    NSTextField *textfield = [self editableTextviewForProperty:@"text"
                                               inViewHierarchy:inspectorView
                                                       binding:NSValueBinding
                                                     viewClass:[NSTextField class]];

    node.name = @"654321";

    [_inspectorController refreshProperty:@"name"];

    SBAssertEqualStrings([textfield stringValue], node.name, @"change to node.name was not updated in inspector view");
}

- (void)testRefreshPropertyForType
{
    CCLabelTTF *label = [self setupInspectorAndSelectedNodeWithPlugin:@"CCLabelTTF"];
    label.string = @"foo";

    [_inspectorController updateInspectorFromSelection];

    NSView *inspectorView = [self viewWithIdentifier:@"TestInspector_string" inView:_inspectorScroll.documentView];

    NSTextView *textView = [self editableTextviewForProperty:@"text"
                                             inViewHierarchy:inspectorView
                                                     binding:NSAttributedStringBinding
                                                   viewClass:[NSTextView class]];

    label.string = @"baa";

    [_inspectorController refreshPropertiesOfType:@"Text"];

    SBAssertEqualStrings([[textView textStorage] string], label.string, @"change to label.string was not updated in inspector view");

}

- (void)testUpdateInspectorFromSelectionForNoSelection
{
    [self setupInspectorAndSelectedNodeWithNodeToBeReturned:nil];

    [_inspectorController updateInspectorFromSelection];

    // _inspectorScroll contains a container view which contains an NSFlippedView. That one should be empty.
    NSView *inspectorViews = [_inspectorScroll.subviews[0] subviews][0];

    XCTAssertEqual(inspectorViews.subviews.count, 0);
}

- (void)testUpdateInspectorFromSelectionForPlugin:(NSString *)pluginClassName withExpectedProperties:(NSArray *)propertyNames codeConnections:(NSArray *)codeConnections
{
    id node = [self setupInspectorAndSelectedNodeWithPlugin:pluginClassName];
    XCTAssertNotNil(node , @"Failed to create plugin node \"%@\"", pluginClassName);

    [_inspectorController updateInspectorFromSelection];

    for (NSString *propertyName in propertyNames)
    {
        NSView *inspectorView = [self viewWithIdentifier:[NSString stringWithFormat:@"TestInspector_%@", propertyName] inView:_inspectorScroll.documentView];
        XCTAssertNotNil(inspectorView, @"No inspector view found for property name \"%@\" and class \"%@\"", propertyName, pluginClassName);
    }

    for (NSString *codeConnectionName in codeConnections)
    {
        NSView *inspectorView = [self viewWithIdentifier:[NSString stringWithFormat:@"TestInspector_%@", codeConnectionName] inView:_inspectoreCodeScroll.documentView];
        XCTAssertNotNil(inspectorView, @"No code inspector view found for property name \"%@\" and class \"%@\"", codeConnectionName, pluginClassName);
    }
}


#pragma mark - Helper


/**
 * Recursively searches a given viewHierarchy for a subview matching the given viewClass and binding parameters:
 *   The binding has to specified, for example NSAttributedStringBinding
 *   The bound property as string. If a keypath ends with boundProperty it is considered a match.
 * Recursive search is breadth first.
 * Will return first hit.
 */
- (id)editableTextviewForProperty:(NSString *)boundProperty inViewHierarchy:(NSView *)viewHierarchy binding:(NSString *)binding viewClass:(Class)viewClass
{
    for (id subview in viewHierarchy.subviews)
    {
        if ([subview isKindOfClass:viewClass])
        {
            NSDictionary *bindingInfo = [subview infoForBinding:binding];
            // NSLog(@"binding info %@", [textView infoForBinding:@"value"]);
            NSString *keyPath = bindingInfo[NSObservedKeyPathKey];

            if ([subview respondsToSelector:@selector(isEditable)]
                && [subview isEditable]
                && [keyPath hasSuffix:boundProperty])
            {
                return subview;
            }
        }

        if ([[subview subviews] count] > 0)
        {
            for (id aSubSubview in [subview subviews])
            {
                NSTextView *result = [self editableTextviewForProperty:boundProperty inViewHierarchy:aSubSubview binding:binding viewClass:viewClass];
                if (result)
                {
                    return result;
                }
            }
        }
    }
    return nil;
}

- (id)setupInspectorAndSelectedNodeWithPlugin:(NSString *)pluginClassName
{
    id node = [[PlugInManager sharedManager] createDefaultNodeOfType:pluginClassName];

    [self setupInspectorAndSelectedNodeWithNodeToBeReturned:node];

    return node;
}

- (void)setupInspectorAndSelectedNodeWithNodeToBeReturned:(id)node
{
    [_inspectorController setupInspectorPane];

    OCMStub([_appDelegate selectedNode]).andReturn(node);
}

- (NSView *)viewWithIdentifier:(NSString *)identifier inView:(NSView *)inView
{
    if (!inView)
    {
        return nil;
    }

    NSArray *subviews = [self allSubviewsInView:inView];

    for (NSView *view in subviews)
    {
        if ([view.identifier isEqualToString:identifier])
        {
            return view;
        }
    }

    return nil;
}

- (NSMutableArray *)allSubviewsInView:(NSView *)parentView
{
    NSMutableArray *allSubviews = [NSMutableArray array];
    NSMutableArray *currentSubviews = [@[parentView] mutableCopy];
    NSMutableArray *newSubviews = [@[parentView] mutableCopy];

    while (newSubviews.count)
    {
        [newSubviews removeAllObjects];

        for (NSView *view in currentSubviews)
        {
            for (NSView *subview in view.subviews)
            {
                [newSubviews addObject:subview];
            }
        }

        [currentSubviews removeAllObjects];
        [currentSubviews addObjectsFromArray:newSubviews];
        [allSubviews addObjectsFromArray:newSubviews];

    }
/*
    for (NSView *view in allSubviews)
    {
        NSLog(@"View: %@, tag: %ld, identifier: %@", view, view.tag, view.identifier);
    }
*/

    return allSubviews;
}

@end
