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


static NSString *const PROPERTY_NAMES_KEY = @"propertyNames";
static NSString *const CODE_CONNECTION_NAMES_KEY = @"codeConnectionNames";


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

/**
 * These tests are high level tests to make sure the inspector is filled with the correct UI elements for most of the plugin nodes
 * Expected properties for item and code connection section are extracted from the pluginInfo of a node
 * Tests rely on the identity property set for the views set in InspectorController(set only for test target).
 */
- (void)testUpdateInspectorFromSelectionForCCNode
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCNode"];
}

- (void)testUpdateInspectorFromSelectionForCCColorNode
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCNodeColor"];
}

- (void)testUpdateInspectorFromSelectionForCCBFile
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCBFile"];
}

- (void)testUpdateInspectorFromSelectionForCCEffectNode
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCEffectNode"];
}

- (void)testUpdateInspectorFromSelectionForCCGradientNode
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCNodeGradient"];
}

- (void)testUpdateInspectorFromSelectionForCCSprite
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCSprite"];
}

- (void)testUpdateInspectorFromSelectionForCCParticleSystem
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCParticleSystem"];
}

- (void)testUpdateInspectorFromSelectionForCCLabelTTF
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCLabelTTF"];
}

- (void)testUpdateInspectorFromSelectionForCCLabelBMFont
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCLabelBMFont"];
}

- (void)testUpdateInspectorFromSelectionForCCButton
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCButton"];
}

- (void)testUpdateInspectorFromSelectionForCCTextField
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCTextField"];
}

- (void)testUpdateInspectorFromSelectionForCCSlider
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCSlider"];
}

- (void)testUpdateInspectorFromSelectionForCCScrollView
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCScrollView"];
}

- (void)testUpdateInspectorFromSelectionForCCLayoutBox
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCLayoutBox"];
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


/**
 * Asserts that a given selected node has all the property ui elements in the scrollViews(Main properties and code connections)
 */
- (void)assertUpdateInspectorFromSelectionForPlugin:(NSString *)pluginClassName
{
    id node = [self setupInspectorAndSelectedNodeWithPlugin:pluginClassName];

    NSDictionary *expectedProperties = [self expectedPropertyNamesForInspector:node];
    NSArray *propertyNames = expectedProperties[PROPERTY_NAMES_KEY];
    NSArray *codeConnectionNames = expectedProperties[CODE_CONNECTION_NAMES_KEY];

    XCTAssertNotNil(node , @"Failed to create plugin node \"%@\"", pluginClassName);

    [_inspectorController updateInspectorFromSelection];

    for (NSString *propertyName in propertyNames)
    {
        NSView *inspectorView = [self viewWithIdentifier:[NSString stringWithFormat:@"TestInspector_%@", propertyName] inView:_inspectorScroll.documentView];
        XCTAssertNotNil(inspectorView, @"No inspector view found for property name \"%@\" and class \"%@\"", propertyName, pluginClassName);
    }

    for (NSString *codeConnectionName in codeConnectionNames)
    {
        NSView *inspectorView = [self viewWithIdentifier:[NSString stringWithFormat:@"TestInspector_%@", codeConnectionName] inView:_inspectoreCodeScroll.documentView];
        XCTAssertNotNil(inspectorView, @"No code inspector view found for property name \"%@\" and class \"%@\"", codeConnectionName, pluginClassName);
    }
}


#pragma mark - Helper

/**
 * Returns a dictionary with two sections:
 *  PROPERTY_NAMES_KEY: contains all names of properties for the item tab
 *  CODE_CONNECTION_NAMES_KEY: contains all names of properties for the code connection
 *
 * Separators, properties without a name field and dontSetInEditor == 1 are ignored
 * Special case is rotationalSkewX and rotationalSkewY are set if flash skew is enabled. Those two replace rotation
 */
- (NSDictionary *)expectedPropertyNamesForInspector:(CCNode *)node
{
    NodeInfo *info = node.userObject;
    PlugInNode *plugIn = info.plugIn;

    NSMutableDictionary *aResult = [@{
            PROPERTY_NAMES_KEY : [NSMutableArray array],
            CODE_CONNECTION_NAMES_KEY : [NSMutableArray array]
    } mutableCopy];

    for (NSDictionary *property in plugIn.nodeProperties)
    {
        NSString *propertyName = property[@"name"];

        if ([propertyName isEqualToString:@"block"])
        {
            NSLog(@"asd");
        }

        if (!propertyName)
        {
            continue;
        }

        if ([property[@"type"] isEqualToString:@"Separator"])
        {
            continue;
        }

        if ([property[@"dontSetInEditor"] integerValue] == 1)
        {
            continue;
        }

        BOOL usesFlashSkew = [[_appDelegate selectedNode] usesFlashSkew];
        if (usesFlashSkew && [propertyName isEqualToString:@"rotation"])
        {
            continue;
        }

        if (!usesFlashSkew && [propertyName isEqualToString:@"rotationalSkewX"])
        {
            continue;
        }

        if (!usesFlashSkew && [propertyName isEqualToString:@"rotationalSkewY"])
        {
            continue;
        }

        if ([property[@"codeConnection"] boolValue])
        {
            [aResult[CODE_CONNECTION_NAMES_KEY] addObject:propertyName];
        }
        else
        {
            [aResult[PROPERTY_NAMES_KEY] addObject:propertyName];
        }
    }

    return aResult;
}

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
