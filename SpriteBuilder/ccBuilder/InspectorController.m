#import <objc/message.h>
#import "InspectorController.h"
#import "InspectorValue.h"
#import "AppDelegate.h"
#import "CocosScene.h"
#import "InspectorSeparator.h"
#import "NSFlippedView.h"
#import "SequencerNodeProperty.h"
#import "SequencerSequence.h"
#import "SequencerHandler.h"
#import "NodeInfo.h"
#import "PlugInNode.h"
#import "CustomPropSetting.h"
#import "PropertyInspectorHandler.h"
#import "InspectorPropertyPaneBuilder.h"

static InspectorController *__sharedInstance = nil;


@interface InspectorController ()

@property (nonatomic, strong) NSMutableDictionary *currentInspectorValues;
@property (nonatomic, strong) NSView *inspectorDocumentView;
@property (nonatomic, strong) NSView *inspectorCodeDocumentView;

@end


@implementation InspectorController

- (id)init
{
    self = [super init];

    if (self)
    {
        self.currentInspectorValues = [NSMutableDictionary dictionary];
    }

    return self;
}

+ (InspectorController *)sharedController
{
    if (!__sharedInstance)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[InspectorController alloc] init];
        });
    }
    return __sharedInstance;
}

+ (void)setSingleton:(InspectorController *)sharedController
{
    __sharedInstance = sharedController;
}

- (void)setupInspectorPane
{
    self.inspectorDocumentView = [[NSFlippedView alloc] initWithFrame:NSMakeRect(0, 0, [_inspectorScroll contentSize].width, 1)];
    [_inspectorDocumentView setAutoresizesSubviews:YES];
    [_inspectorDocumentView setAutoresizingMask:NSViewWidthSizable];
    [_inspectorScroll setDocumentView:_inspectorDocumentView];

    self.inspectorCodeDocumentView = [[NSFlippedView alloc] initWithFrame:NSMakeRect(0, 0, [_inspectorCodeScroll contentSize].width, 1)];
    [_inspectorCodeDocumentView setAutoresizesSubviews:YES];
    [_inspectorCodeDocumentView setAutoresizingMask:NSViewWidthSizable];
    [_inspectorCodeScroll setDocumentView:_inspectorCodeDocumentView];
}

- (void)refreshProperty:(NSString *)name
{
    if (![_appDelegate selectedNode])
    {
        return;
    }

    InspectorValue *inspectorValue = _currentInspectorValues[name];
    if (inspectorValue)
    {
        [inspectorValue refresh];
    }
}

- (void)refreshPropertiesOfType:(NSString *)type
{
    if (![_appDelegate selectedNode])
    {
        return;
    }

    for (NSString *name in _currentInspectorValues)
    {
        InspectorValue *inspectorValue = _currentInspectorValues[name];
        if ([inspectorValue.propertyType isEqualToString:type])
        {
            [inspectorValue refresh];
        }
    }
}

- (void)updateInspectorFromSelection
{
    InspectorPropertyPaneBuilder *builder = [[InspectorPropertyPaneBuilder alloc] initWithNode:[_appDelegate selectedNode]];
    builder.inspectorCodeDocumentView = _inspectorCodeDocumentView;
    builder.inspectorDocumentView = _inspectorDocumentView;
    builder.propertyInspectorHandler = _propertyInspectorHandler;
    builder.inspectorCodeScroll = _inspectorCodeScroll;
    builder.inspectorScroll = _inspectorScroll;
    builder.cocosScene = _cocosScene;
    builder.sequenceHandler = _sequenceHandler;
    builder.inspectorPhysics = _inspectorPhysics;

    self.currentInspectorValues = [builder buildAndCreatePropertyViewMap];
}

@end
