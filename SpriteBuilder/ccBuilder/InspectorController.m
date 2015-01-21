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
#import "PropertyInspectorTemplateHandler.h"
#import "InspectorPropertyPaneBuilder.h"

static InspectorController *__sharedInstance = nil;


@interface InspectorController ()

@property (nonatomic, strong) NSMutableDictionary *currentInspectorValuesMap;
@property (nonatomic, strong) NSView *inspectorDocumentView;
@property (nonatomic, strong) NSView *inspectorCodeDocumentView;

@end


@implementation InspectorController

- (id)init
{
    self = [super init];

    if (self)
    {
        self.currentInspectorValuesMap = [NSMutableDictionary dictionary];
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

- (void)refreshAllProperties
{
    if (![_appDelegate selectedNode])
    {
        return;
    }
    
    for (NSString *name in _currentInspectorValuesMap)
    {
        InspectorValue *inspectorValue = _currentInspectorValuesMap[name];
        [inspectorValue refresh];
    }
}

- (void)refreshProperty:(NSString *)name
{
    if (![_appDelegate selectedNode])
    {
        return;
    }

    InspectorValue *inspectorValue = _currentInspectorValuesMap[name];
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

    for (NSString *name in _currentInspectorValuesMap)
    {
        InspectorValue *inspectorValue = _currentInspectorValuesMap[name];
        if ([inspectorValue.propertyType isEqualToString:type])
        {
            [inspectorValue refresh];
        }
    }
}

- (void)updateInspectorFromSelection
{
    [_currentInspectorValuesMap removeAllObjects];

    [self buildInspectorPaneWithDocumentView:_inspectorDocumentView
                                   scrollView:_inspectorScroll
                         isCodeConnectionPane:NO];

    [self buildInspectorPaneWithDocumentView:_inspectorCodeDocumentView
                                  scrollView:_inspectorCodeScroll
                        isCodeConnectionPane:YES];

    [_propertyInspectorTemplateHandler updateTemplates];
}

- (void)buildInspectorPaneWithDocumentView:(NSView *)documentView scrollView:(NSScrollView *)scrollView isCodeConnectionPane:(BOOL)isCodeConnectionPane
{
    InspectorPropertyPaneBuilder *builder = [[InspectorPropertyPaneBuilder alloc] initWithIsCodeConnectionPane:isCodeConnectionPane
                                                                                                           node:[_appDelegate selectedNode]];
    builder.cocosScene = _cocosScene;
    builder.sequenceHandler = _sequenceHandler;
    builder.inspectorPhysics = _inspectorPhysics;
    builder.currentScrollView = scrollView;
    builder.currentView = documentView;

    NSDictionary *inspectorValuesMap = [builder buildAndCreatePropertyViewMap];

    [self.currentInspectorValuesMap addEntriesFromDictionary:inspectorValuesMap];
}

@end
