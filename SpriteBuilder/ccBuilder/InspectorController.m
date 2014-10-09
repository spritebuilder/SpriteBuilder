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


static InspectorValue *__lastInspectorValue;
static BOOL __hideAllToNextSeparator;


@interface InspectorController ()

@property (nonatomic, strong) NSMutableDictionary *currentInspectorValues;
@property (nonatomic, strong) NSView *inspectorDocumentView;
@property (nonatomic, strong) NSView *inspectorCodeDocumentView;

@end

static InspectorController *__sharedInstance = nil;

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
                             name:(NSString *)prop
                      displayName:(NSString *)displayName
                            extra:(NSString *)extra
                         readOnly:(BOOL)readOnly
                     affectsProps:(NSArray *)affectsProps
                         atOffset:(int)offset
                 isCodeConnection:(BOOL)isCodeConnection
{
    NSString *inspectorNibName = [NSString stringWithFormat:@"Inspector%@", type];

    // Create inspector
    InspectorValue *inspectorValue = [InspectorValue inspectorOfType:type
                                                       withSelection:[_appDelegate selectedNode]
                                                     andPropertyName:prop
                                                      andDisplayName:displayName
                                                            andExtra:extra];
    NSAssert3(inspectorValue, @"property '%@' (%@) not found in class %@", prop, type, NSStringFromClass([[_appDelegate selectedNode] class]));

    __lastInspectorValue.inspectorValueBelow = inspectorValue;
    __lastInspectorValue = inspectorValue;
    inspectorValue.readOnly = readOnly;
    inspectorValue.rootNode = ([_appDelegate selectedNode] == _cocosScene.rootNode);

    // Save a reference in case it needs to be updated
    if (prop)
    {
        _currentInspectorValues[prop] = inspectorValue;
    }

    if (affectsProps)
    {
        inspectorValue.affectsProperties = affectsProps;
    }

    @try
    {
        // Load it's associated view
        // FIXME: fix deprecation warning
        SUPPRESS_DEPRECATED([NSBundle loadNibNamed:inspectorNibName owner:inspectorValue]);
    }
    @catch (NSException *exception)
    {


    }
    NSView *view = inspectorValue.view;

    [inspectorValue willBeAdded];

    //if its a separator, check to see if it isExpanded, if not set all of the next non-separator InspectorValues to hidden and don't touch the offset
    if ([inspectorValue isKindOfClass:[InspectorSeparator class]])
    {
        InspectorSeparator *inspectorSeparator = (InspectorSeparator *) inspectorValue;
        __hideAllToNextSeparator = NO;
        if (!inspectorSeparator.isExpanded)
        {
            __hideAllToNextSeparator = YES;
        }
        NSRect frame = [view frame];
        [view setFrame:NSMakeRect(0, offset, frame.size.width, frame.size.height)];
        offset += frame.size.height;
    }
    else
    {
        if (__hideAllToNextSeparator)
        {
            [view setHidden:YES];
        }
        else
        {
            NSRect frame = [view frame];
            [view setFrame:NSMakeRect(0, offset, frame.size.width, frame.size.height)];
            offset += frame.size.height;
        }
    }

    // Add view to inspector and place it at the bottom
    if (isCodeConnection)
    {
        [_inspectorCodeDocumentView addSubview:view];
    }
    else
    {
        [_inspectorDocumentView addSubview:view];
    }
    [view setAutoresizingMask:NSViewWidthSizable];

    return offset;
}

- (BOOL)isDisabledProperty:(NSString *)name animatable:(BOOL)animatable
{
    // Only animatable properties can be disabled
    if (!animatable)
    {
        return NO;
    }

    SequencerSequence *seq = _sequenceHandler.currentSequence;

    SequencerNodeProperty *seqNodeProp = [[_appDelegate selectedNode] sequenceNodeProperty:name sequenceId:seq.sequenceId];

    // Do not disable if animation hasn't been enabled
    if (!seqNodeProp)
    {
        return NO;
    }

    // Disable visiblilty if there are keyframes
    if (seqNodeProp.keyframes.count > 0 && [name isEqualToString:@"visible"])
    {
        return YES;
    }

    // Do not disable if we are currently at a keyframe
    if ([seqNodeProp hasKeyframeAtTime:seq.timelinePosition])
    {
        return NO;
    }

    // Between keyframes - disable
    return YES;
}

- (void)updateInspectorFromSelection
{
    // Notifiy panes that they will be removed
    for (NSString *key in _currentInspectorValues)
    {
        InspectorValue *v = _currentInspectorValues[key];
        [v willBeRemoved];
    }

    // Remove all old inspector panes
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

    // Reset frame sizes
    [_inspectorDocumentView setFrameSize:NSMakeSize(233, 1)];
    [_inspectorCodeDocumentView setFrameSize:NSMakeSize(233, 1)];
    int paneOffset = 0;
    int paneCodeOffset = 0;
    bool displayPluginProperties = YES;

    // Add show panes according to selections
    if (![_appDelegate selectedNode])
    {
        return;
    }

    NodeInfo *info = [_appDelegate selectedNode].userObject;
    PlugInNode *plugIn = info.plugIn;

    BOOL isCCBSubFile = [plugIn.nodeClassName isEqualToString:@"CCBFile"];

    // Always add the code connections pane
    if (!plugIn.isJoint)
    {
        paneCodeOffset = [self addInspectorPropertyOfType:@"CodeConnections"
                                                     name:@"customClass"
                                              displayName:@""
                                                    extra:NULL
                                                 readOnly:isCCBSubFile
                                             affectsProps:NULL
                                                 atOffset:paneOffset
                                         isCodeConnection:YES];

        [_inspectorPhysics setHidden:NO];
    }
    else
    {
        [_inspectorPhysics setHidden:YES];

        if ([_sequenceHandler currentSequence].timelinePosition != 0.0f
            || ![_sequenceHandler currentSequence].autoPlay)
        {
            paneOffset = [self addInspectorPropertyOfType:@"PhysicsUnavailable"
                                                     name:@"name"
                                              displayName:nil
                                                    extra:@""
                                                 readOnly:YES
                                             affectsProps:nil
                                                 atOffset:0
                                         isCodeConnection:NO];
            displayPluginProperties = NO;
        }
    }

    // Add panes for each property

    if (plugIn && displayPluginProperties)
    {
        NSArray *propInfos = plugIn.nodeProperties;
        for (int i = 0; i < [propInfos count]; i++)
        {
            NSDictionary *propInfo = propInfos[(NSUInteger) i];
            NSString *type = propInfo[@"type"];
            NSString *name = propInfo[@"name"];
            NSString *displayName = propInfo[@"displayName"];

            NSArray *affectsProps = propInfo[@"affectsProperties"];
            NSString *extra = propInfo[@"extra"];
            BOOL animated = [propInfo[@"animatable"] boolValue];
            BOOL isCodeConnection = [propInfo[@"codeConnection"] boolValue];
            BOOL inspectorDisabled = [propInfo[@"inspectorDisabled"] boolValue];
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
            if (usesFlashSkew && [name isEqualToString:@"rotation"])
            {
                continue;
            }
            if (!usesFlashSkew && [name isEqualToString:@"rotationalSkewX"])
            {
                continue;
            }
            if (!usesFlashSkew && [name isEqualToString:@"rotationalSkewY"])
            {
                continue;
            }

            // Handle read only for animated properties
            //For the separators; should make this a part of the definition
            if (name == NULL)
            {
                name = displayName;
            }

            if (!inspectorDisabled)
            {
                if (isCodeConnection)
                {
                    paneCodeOffset = [self addInspectorPropertyOfType:type
                                                                 name:name
                                                          displayName:displayName
                                                                extra:extra
                                                             readOnly:readOnly
                                                         affectsProps:affectsProps
                                                             atOffset:paneCodeOffset
                                                     isCodeConnection:YES];
                }
                else
                {
                    paneOffset = [self addInspectorPropertyOfType:type
                                                             name:name
                                                      displayName:displayName
                                                            extra:extra
                                                         readOnly:readOnly
                                                     affectsProps:affectsProps
                                                         atOffset:paneOffset
                                                 isCodeConnection:NO];
                }
            }
        }
    }
    else
    {
        NSLog(@"WARNING info:%@ plugIn:%@ selectedNode: %@", info, plugIn, [_appDelegate selectedNode]);
    }

    // Custom properties
    NSString *customClass = [[_appDelegate selectedNode] extraPropForKey:@"customClass"];
    NSArray *customProps = [_appDelegate selectedNode].customProperties;
    if (customClass && ![customClass isEqualToString:@""])
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
    }

    __hideAllToNextSeparator = NO;

    [_inspectorDocumentView setFrameSize:NSMakeSize([_inspectorScroll contentSize].width, paneOffset)];
    [_inspectorCodeDocumentView setFrameSize:NSMakeSize([_inspectorCodeScroll contentSize].width, paneCodeOffset)];

    [_propertyInspectorHandler updateTemplates];

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

@end