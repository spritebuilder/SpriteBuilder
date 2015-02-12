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
#import "PropertyInspectorTemplateHandler.h"
#import "CocosScene.h"
#import "SequencerHandler.h"
#import "PlugInManager.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "SBAssserts.h"
#import "SequencerSequence.h"


static NSString *const PROPERTY_NAMES_KEY = @"propertyNames";
static NSString *const CODE_CONNECTION_NAMES_KEY = @"codeConnectionNames";


@interface InspectoreController_Tests : XCTestCase

@property (nonatomic, strong) InspectorController *inspectorController;
@property (nonatomic, strong) NSScrollView *inspectorScroll;
@property (nonatomic, strong) NSScrollView *inspectoreCodeScroll;
@property (nonatomic, strong) NSView *inspectorPhysics;
@property (nonatomic, strong) id propertyInspectorTemplateHandler;
@property (nonatomic, strong) id cocosScene;
@property (nonatomic, strong) id sequenceHandler;
@property (nonatomic, strong) id appDelegate;
@property (nonatomic, strong) id sequenceMock;

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
    self.propertyInspectorTemplateHandler = [OCMockObject niceMockForClass:[PropertyInspectorTemplateHandler class]];
    self.cocosScene = [OCMockObject niceMockForClass:[CocosScene class]];
    self.sequenceHandler = [OCMockObject niceMockForClass:[SequencerHandler class]];
    self.appDelegate = [OCMockObject niceMockForClass:[AppDelegate class]];

    _inspectorController.inspectorScroll = _inspectorScroll;
    _inspectorController.inspectorCodeScroll = _inspectoreCodeScroll;
    _inspectorController.inspectorPhysics = _inspectorPhysics;
    _inspectorController.propertyInspectorTemplateHandler = _propertyInspectorTemplateHandler;
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

/*
 * Disabled as long as https://github.com/spritebuilder/SpriteBuilder/issues/897 is not resolved
 */

- (void)testUpdateInspectorFromSelectionForCCSprite9Slice
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCSprite9Slice" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCNode
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCNode" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCColorNode
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCNodeColor" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCBFile
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCBFile" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCEffectNode
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCEffectNode" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCGradientNode
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCNodeGradient" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCSprite
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCSprite" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCParticleSystem
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCParticleSystem" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCLabelTTF
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCLabelTTF" expectCustomClassInCodeConnection:YES];
}

//- (void)testUpdateInspectorFromSelectionForCCLabelBMFont
//{
//    [self assertUpdateInspectorFromSelectionForPlugin:@"CCLabelBMFont" expectCustomClassInCodeConnection:YES];
//}

- (void)testUpdateInspectorFromSelectionForCCButton
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCButton" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCTextField
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCTextField" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCSlider
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCSlider" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCScrollView
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCScrollView" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCLayoutBox
{
    [self assertUpdateInspectorFromSelectionForPlugin:@"CCLayoutBox" expectCustomClassInCodeConnection:YES];
}

- (void)testUpdateInspectorFromSelectionForCCPhysicsSpringJoint
{
    [self setupSequenceMockForPhysicsJointsWithAutplay:YES];

    [self assertUpdateInspectorFromSelectionForPlugin:@"CCPhysicsSpringJoint" expectCustomClassInCodeConnection:NO];
}

- (void)testUpdateInspectorFromSelectionForCCPhysicsPivotJoint
{
    [self setupSequenceMockForPhysicsJointsWithAutplay:YES];

    [self assertUpdateInspectorFromSelectionForPlugin:@"CCPhysicsPivotJoint" expectCustomClassInCodeConnection:NO];
}

- (void)testUpdateInspectorFromSelectionForCCPhysicsPinJoint
{
    [self setupSequenceMockForPhysicsJointsWithAutplay:YES];

    [self assertUpdateInspectorFromSelectionForPlugin:@"CCPhysicsPinJoint" expectCustomClassInCodeConnection:NO];
}

- (void)testUpdateInspectorFromSelectionForCCPhysicsNode
{
    [self setupSequenceMockForPhysicsJointsWithAutplay:YES];

    [self assertUpdateInspectorFromSelectionForPlugin:@"CCPhysicsNode" expectCustomClassInCodeConnection:NO];
}

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
- (void)assertUpdateInspectorFromSelectionForPlugin:(NSString *)pluginClassName expectCustomClassInCodeConnection:(BOOL)expectCustomClassInCodeConnection
{
    CCNode *node = [self setupInspectorAndSelectedNodeWithPlugin:pluginClassName];
    NodeInfo *info = node.userObject;
    PlugInNode *plugIn = info.plugIn;

    NSDictionary *expectedProperties = [self expectedPropertyNamesForInspector:node];
    NSArray *propertyNames = expectedProperties[PROPERTY_NAMES_KEY];
    NSMutableArray *codeConnectionNames = [expectedProperties[CODE_CONNECTION_NAMES_KEY] mutableCopy];

    if (expectCustomClassInCodeConnection)
    {
        [codeConnectionNames addObject:@"customClass"];
    }

    XCTAssertNotNil(node , @"Failed to create plugin node \"%@\"", pluginClassName);

    [_inspectorController updateInspectorFromSelection];

    for (NSString *propertyName in propertyNames)
    {
        NSView *inspectorView = [self viewWithIdentifier:[NSString stringWithFormat:@"TestInspector_%@", propertyName]
                                                  inView:_inspectorScroll.documentView];

        XCTAssertNotNil(inspectorView, @"No inspector view found for property name \"%@\" and class \"%@\". All node properties in plugin info: %@",
                        propertyName, pluginClassName, plugIn.nodeProperties);

        NSView *notExpectedView = [self viewWithIdentifier:[NSString stringWithFormat:@"TestInspector_%@", propertyName]
                                                    inView:_inspectoreCodeScroll.documentView];

        XCTAssertNil(notExpectedView, @"Unexpected inspector view found in code connections tab for property name \"%@\" and class \"%@\".",
                        propertyName, pluginClassName);
    }

    for (NSString *codeConnectionName in codeConnectionNames)
    {
        NSView *inspectorView = [self viewWithIdentifier:[NSString stringWithFormat:@"TestInspector_%@", codeConnectionName]
                                                  inView:_inspectoreCodeScroll.documentView];

        XCTAssertNotNil(inspectorView, @"No code inspector view found for property name \"%@\" and class \"%@\". All node properties in plugin info: %@",
                        codeConnectionName, pluginClassName, plugIn.nodeProperties);

        NSView *notExpectedView = [self viewWithIdentifier:[NSString stringWithFormat:@"TestInspector_%@", codeConnectionName]
                                                    inView:_inspectorScroll.documentView];

        XCTAssertNil(notExpectedView, @"Unexpected inspector view found in main tab for property name \"%@\" and class \"%@\".",
                        codeConnectionName, pluginClassName);
    }
}


#pragma mark - Helper

/**
 * Returns a dictionary with two sections:
 *  PROPERTY_NAMES_KEY: contains all names of properties for the item tab
 *  CODE_CONNECTION_NAMES_KEY: contains all names of properties for the code connection
 *
 * Separators, properties without a name field, inspectorDisabled == 1 and dontSetInEditor == 1 are ignored
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

        if (!propertyName
            || [property[@"type"] isEqualToString:@"Separator"]
            || [property[@"dontSetInEditor"] integerValue] == 1
            || [property[@"inspectorDisabled"] integerValue] == 1)
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

/**
 * The sequenceHandlers currentSequence is queried for phyics properties
 */
- (void)setupSequenceMockForPhysicsJointsWithAutplay:(BOOL)autoPlayEnabled
{
    self.sequenceMock = [OCMockObject niceMockForClass:[SequencerSequence class]];
    [[[_sequenceMock stub] andReturnValue:@(autoPlayEnabled)] autoPlay];
    [[[_sequenceMock stub] andReturnValue:@0.0] timelinePosition];
    OCMStub([_sequenceHandler currentSequence]).andReturn(_sequenceMock);
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
