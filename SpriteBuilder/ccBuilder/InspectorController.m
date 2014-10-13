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

static InspectorController *__sharedInstance = nil;


@interface InspectorController ()

@property (nonatomic, strong) NSMutableDictionary *currentInspectorValues;
@property (nonatomic, strong) NSView *inspectorDocumentView;
@property (nonatomic, strong) NSView *inspectorCodeDocumentView;
@property (nonatomic, weak) InspectorValue *lastInspectorValue;
@property (nonatomic) BOOL hideAllToNextSeparator;

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

- (int)addInspectorPropertyOfType:(NSString *)type
                             name:(NSString *)name
                      displayName:(NSString *)displayName
                            extra:(NSString *)extra
                         readOnly:(BOOL)readOnly
                     affectsProps:(NSArray *)affectsProps
                         atOffset:(int)atOffset
                 isCodeConnection:(BOOL)isCodeConnection
{
    InspectorValue *inspectorValue = [InspectorValue inspectorOfType:type
                                                       withSelection:[_appDelegate selectedNode]
                                                     andPropertyName:name
                                                      andDisplayName:displayName
                                                            andExtra:extra];
    NSAssert3(inspectorValue, @"property '%@' (%@) not found in class %@", name, type, NSStringFromClass([[_appDelegate selectedNode] class]));

    [self saveLastInspectorValue:inspectorValue];

    [self configureInspectorValue:readOnly affectsProps:affectsProps inspectorValue:inspectorValue];

    [self saveInspectorValueForFutureUpdates:name inspectorValue:inspectorValue];

    [self loadNibWithType:type inspectorValue:inspectorValue];

    [inspectorValue willBeAdded];

    NSView *inspectorValuesView = inspectorValue.view;

    #ifdef TESTING
    inspectorValuesView.identifier = [NSString stringWithFormat:@"TestInspector_%@", name];
    #endif

    //if its a separator, check to see if it isExpanded, if not set all of the next non-separator InspectorValues to hidden and don't touch the offset
    atOffset = [inspectorValue isKindOfClass:[InspectorSeparator class]]
        ? [self addSeparator:atOffset inspectorValue:inspectorValue inspectorValuesView:inspectorValuesView]
        : [self toggleVisibilityToNextSeparator:atOffset inspectorValuesView:inspectorValuesView];

    [self addViewToCorrespondingTabAndPlaceAtBottom:isCodeConnection inspectorValuesView:inspectorValuesView];

    [inspectorValuesView setAutoresizingMask:NSViewWidthSizable];

    return atOffset;
}

- (void)saveLastInspectorValue:(InspectorValue *)inspectorValue
{
    _lastInspectorValue.inspectorValueBelow = inspectorValue;
    self.lastInspectorValue = inspectorValue;
}

- (void)configureInspectorValue:(BOOL)readOnly affectsProps:(NSArray *)affectsProps inspectorValue:(InspectorValue *)inspectorValue
{
    inspectorValue.readOnly = readOnly;
    inspectorValue.rootNode = ([_appDelegate selectedNode] == _cocosScene.rootNode);
    inspectorValue.affectsProperties = affectsProps;
}

- (void)saveInspectorValueForFutureUpdates:(NSString *)propName inspectorValue:(InspectorValue *)inspectorValue
{
    if (propName)
    {
        _currentInspectorValues[propName] = inspectorValue;
    }
}

- (void)addViewToCorrespondingTabAndPlaceAtBottom:(BOOL)isCodeConnection inspectorValuesView:(NSView *)inspectorValuesView
{
    if (isCodeConnection)
    {
        [_inspectorCodeDocumentView addSubview:inspectorValuesView];
    }
    else
    {
        [_inspectorDocumentView addSubview:inspectorValuesView];
    }
}

- (int)toggleVisibilityToNextSeparator:(int)offset inspectorValuesView:(NSView *)inspectorValuesView
{
    if (_hideAllToNextSeparator)
    {
        [inspectorValuesView setHidden:YES];
    }
    else
    {
        NSRect frame = [inspectorValuesView frame];
        [inspectorValuesView setFrame:NSMakeRect(0, offset, frame.size.width, frame.size.height)];
        offset += frame.size.height;
    }
    return offset;
}

- (int)addSeparator:(int)offset inspectorValue:(InspectorValue *)inspectorValue inspectorValuesView:(NSView *)inspectorValuesView
{
    InspectorSeparator *inspectorSeparator = (InspectorSeparator *) inspectorValue;

    self.hideAllToNextSeparator = !inspectorSeparator.isExpanded;

    NSRect frame = [inspectorValuesView frame];
    [inspectorValuesView setFrame:NSMakeRect(0, offset, frame.size.width, frame.size.height)];
    offset += frame.size.height;
    return offset;
}

- (void)loadNibWithType:(NSString *)type inspectorValue:(InspectorValue *)inspectorValue
{
    NSString *inspectorNibName = [NSString stringWithFormat:@"Inspector%@", type];
    @try
    {
        [[NSBundle mainBundle] loadNibNamed:inspectorNibName owner:inspectorValue topLevelObjects:nil];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception loading inspector nib \"%@\": %@, origin: %@", inspectorNibName, exception, [NSThread callStackSymbols]);
    }
}

- (BOOL)isDisabledProperty:(NSString *)name animatable:(BOOL)animatable
{
    // Only animatable properties can be disabled
    if (!animatable)
    {
        return NO;
    }

    SequencerSequence *sequence = _sequenceHandler.currentSequence;
    SequencerNodeProperty *sequencerNodeProperty = [[_appDelegate selectedNode] sequenceNodeProperty:name sequenceId:sequence.sequenceId];

    // Do not disable if animation hasn't been enabled
    if (!sequencerNodeProperty)
    {
        return NO;
    }

    // Disable visiblilty if there are keyframes
    if (sequencerNodeProperty.keyframes.count > 0 && [name isEqualToString:@"visible"])
    {
        return YES;
    }

    // Do not disable if we are currently at a keyframe
    if ([sequencerNodeProperty hasKeyframeAtTime:sequence.timelinePosition])
    {
        return NO;
    }

    // Between keyframes - disable
    return YES;
}

- (void)updateInspectorFromSelection
{
    [self notifyPanesThatWillBeRemoved];

    [self removeAllOldInspectorPanes];

    [self resetInspectorContainerViewFrames];

    int paneOffset = 0;
    int paneCodeOffset = 0;
    BOOL displayPluginProperties = YES;

    if (![_appDelegate selectedNode])
    {
        return;
    }

    NodeInfo *info = [_appDelegate selectedNode].userObject;
    PlugInNode *plugIn = info.plugIn;

    if (plugIn.isJoint)
    {
        paneOffset = [self disableStandardPropertiesAndTogglePhysicsWarningViewDisplayPluginProperties:&displayPluginProperties];
    }
    else
    {
        paneCodeOffset = [self addCodeConnectionsPane:paneOffset plugIn:plugIn];
    }

    if (plugIn && displayPluginProperties)
    {
        [self addProperties:plugIn paneOffset:&paneOffset paneCodeOffset:&paneCodeOffset];
    }
    else
    {
        NSLog(@"WARNING info:%@ plugIn:%@ selectedNode: %@", info, plugIn, [_appDelegate selectedNode]);
    }

    paneOffset = [self addCustomProperties:paneOffset plugIn:plugIn];

    self.hideAllToNextSeparator = NO;

    [_inspectorDocumentView setFrameSize:NSMakeSize([_inspectorScroll contentSize].width, paneOffset)];
    [_inspectorCodeDocumentView setFrameSize:NSMakeSize([_inspectorCodeScroll contentSize].width, paneCodeOffset)];

    [_propertyInspectorHandler updateTemplates];

    [self resetKeyViewLoop];
}

- (void)resetKeyViewLoop
{
    NSString *privateFunction = [NSString stringWithFormat:@"%@%@%@", @"_setDefault", @"KeyView", @"Loop"];
    SEL privateSelector = NSSelectorFromString(privateFunction);

    //Undocumented function that resets the KeyViewLoop.
    if ([_inspectorDocumentView respondsToSelector:privateSelector])
    {
        objc_msgSend(_inspectorDocumentView, privateSelector);
    }

    //Undocumented function that resets the KeyViewLoop.
    if ([_inspectorCodeDocumentView respondsToSelector:privateSelector])
    {
        objc_msgSend(_inspectorCodeDocumentView, privateSelector);
    }
}

- (int)addCustomProperties:(int)paneOffset plugIn:(PlugInNode *)plugIn
{
    NSString *customClass = [[_appDelegate selectedNode] extraPropForKey:@"customClass"];
    NSArray *customProps = [_appDelegate selectedNode].customProperties;
    if (customClass && ![customClass isEqualToString:@""])
    {
        BOOL isCCBSubFile = [plugIn.nodeClassName isEqualToString:@"CCBFile"];

        paneOffset = [self addSeparatorForCustomProperty:paneOffset customProps:customProps isCCBSubFile:isCCBSubFile];

        paneOffset = [self addCustomPropertySettings:paneOffset customProps:customProps];

        paneOffset = [self addCustomEditForCustomProperty:paneOffset isCCBSubFile:isCCBSubFile];
    }
    return paneOffset;
}

- (int)addCustomEditForCustomProperty:(int)paneOffset isCCBSubFile:(BOOL)isCCBSubFile
{
    if (!isCCBSubFile)
    {
        paneOffset = [self addInspectorPropertyOfType:@"CustomEdit"
                                                 name:NULL
                                          displayName:@""
                                                extra:NULL
                                             readOnly:NO
                                         affectsProps:NULL
                                             atOffset:paneOffset
                                     isCodeConnection:NO];
    }
    return paneOffset;
}

- (int)addCustomPropertySettings:(int)paneOffset customProps:(NSArray *)customProps
{
    for (CustomPropSetting *setting in customProps)
    {
        paneOffset = [self addInspectorPropertyOfType:@"Custom"
                                                 name:setting.name
                                          displayName:setting.name
                                                extra:NULL
                                             readOnly:NO
                                         affectsProps:NULL
                                             atOffset:paneOffset
                                     isCodeConnection:NO];
    }
    return paneOffset;
}

- (int)addSeparatorForCustomProperty:(int)paneOffset customProps:(NSArray *)customProps isCCBSubFile:(BOOL)isCCBSubFile
{
    if ([customProps count] || !isCCBSubFile)
    {
        paneOffset = [self addInspectorPropertyOfType:@"Separator"
                                                 name:[[_appDelegate selectedNode] extraPropForKey:@"customClass"]
                                          displayName:[[_appDelegate selectedNode] extraPropForKey:@"customClass"]
                                                extra:NULL
                                             readOnly:YES
                                         affectsProps:NULL
                                             atOffset:paneOffset
                                     isCodeConnection:NO];
    }
    return paneOffset;
}

- (void)addProperties:(PlugInNode *)plugIn paneOffset:(int *)paneOffset paneCodeOffset:(int *)paneCodeOffset
{
    NSArray *propInfos = plugIn.nodeProperties;
    for (int i = 0; i < [propInfos count]; i++)
    {
        NSDictionary *propInfo = propInfos[(NSUInteger) i];
        BOOL animated = [propInfo[@"animatable"] boolValue];
        NSString *name = propInfo[@"name"];

        if ([name isEqualToString:@"visible"])
        {
            animated = YES;
        }

        BOOL readOnly = [propInfo[@"readOnly"] boolValue];
        if ([self isDisabledProperty:name animatable:animated])
        {
            readOnly = YES;
        }

        // Handle Flash skews
        BOOL usesFlashSkew = [[_appDelegate selectedNode] usesFlashSkew];
        if ((usesFlashSkew && [name isEqualToString:@"rotation"])
            || (!usesFlashSkew && [name isEqualToString:@"rotationalSkewX"])
            || (!usesFlashSkew && [name isEqualToString:@"rotationalSkewY"]))
        {
            continue;
        }

        // Handle read only for animated properties
        //For the separators; should make this a part of the definition
        if (name == NULL)
        {
            name = propInfo[@"displayName"];
        }

        if (![propInfo[@"inspectorDisabled"] boolValue])
        {
            if ([propInfo[@"codeConnection"] boolValue])
            {
                (*paneCodeOffset) = [self addInspectorPropertyOfType:propInfo[@"type"]
                                                                name:name
                                                         displayName:propInfo[@"displayName"]
                                                               extra:propInfo[@"extra"]
                                                            readOnly:readOnly
                                                        affectsProps:propInfo[@"affectsProperties"]
                                                            atOffset:*paneCodeOffset
                                                    isCodeConnection:YES];
            }
            else
            {
                (*paneOffset) = [self addInspectorPropertyOfType:propInfo[@"type"]
                                                            name:name
                                                     displayName:propInfo[@"displayName"]
                                                           extra:propInfo[@"extra"]
                                                        readOnly:readOnly
                                                    affectsProps:propInfo[@"affectsProperties"]
                                                        atOffset:*paneOffset
                                                isCodeConnection:NO];
            }
        }
    }
}

- (int)disableStandardPropertiesAndTogglePhysicsWarningViewDisplayPluginProperties:(BOOL *)displayPluginProperties
{
    [_inspectorPhysics setHidden:YES];

    if ([self isPhysicUnavailableAvailable])
    {
        (*displayPluginProperties) = NO;
        return [self addInspectorPropertyOfType:@"PhysicsUnavailable"
                                                 name:@"name"
                                          displayName:nil
                                                extra:@""
                                             readOnly:YES
                                         affectsProps:nil
                                             atOffset:0
                                     isCodeConnection:NO];
    }

    return 0;
}

- (BOOL)isPhysicUnavailableAvailable
{
    return [_sequenceHandler currentSequence].timelinePosition != 0.0f
            || ![_sequenceHandler currentSequence].autoPlay;
}

- (int)addCodeConnectionsPane:(int)paneOffset plugIn:(PlugInNode *)plugIn
{
    int paneCodeOffset = [self addInspectorPropertyOfType:@"CodeConnections"
                                                     name:@"customClass"
                                              displayName:@""
                                                    extra:NULL
                                                 readOnly:[plugIn.nodeClassName isEqualToString:@"CCBFile"]
                                             affectsProps:NULL
                                                 atOffset:paneOffset
                                         isCodeConnection:YES];

    [_inspectorPhysics setHidden:NO];
    return paneCodeOffset;
}

- (void)resetInspectorContainerViewFrames
{
    [_inspectorDocumentView setFrameSize:NSMakeSize(233, 1)];
    [_inspectorCodeDocumentView setFrameSize:NSMakeSize(233, 1)];
}

- (void)removeAllOldInspectorPanes
{
    NSArray *panes = [_inspectorDocumentView subviews];
    for (int i = [panes count] - 1; i >= 0; i--)
    {
        NSView *pane = panes[(NSUInteger) i];
        [pane removeFromSuperview];
    }
    panes = [_inspectorCodeDocumentView subviews];
    for (int i = [panes count] - 1; i >= 0; i--)
    {
        NSView *pane = panes[(NSUInteger) i];
        [pane removeFromSuperview];
    }
    [_currentInspectorValues removeAllObjects];
}

- (void)notifyPanesThatWillBeRemoved
{
    for (NSString *key in _currentInspectorValues)
    {
        InspectorValue *inspectorValue = _currentInspectorValues[key];
        [inspectorValue willBeRemoved];
    }
}

@end
