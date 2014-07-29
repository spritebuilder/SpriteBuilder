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

#import "SequencerHandler.h"
#import "SceneGraph.h"
#import "AppDelegate.h"
#import "NodeInfo.h"
#import "CCNode+NodeInfo.h"
#import "PlugInNode.h"
#import "CCBWriterInternal.h"
#import "CCBReaderInternal.h"
#import "SequencerExpandBtnCell.h"
#import "SequencerStructureCell.h"
#import "SequencerCell.h"
#import "SequencerSequence.h"
#import "SequencerScrubberSelectionView.h"
#import "SequencerKeyframe.h"
#import "SequencerKeyframeEasing.h"
#import "SequencerNodeProperty.h"
#import "SequencerButtonCell.h"
#import "CCBDocument.h"
#import "SequencerCallbackChannel.h"
#import "SequencerSoundChannel.h"
#import "NSPasteboard+CCB.h"
#import "MainWindow.h"
#import "NSArray+Query.h"
#import "CCBPhysicsJoint.h"
#import "PlugInManager.h"

// TODO: move these to a constants file and replace hard coded strings in project with constants.
static NSString *const PASTEBOARD_TYPE_NODE = @"com.cocosbuilder.node";
static NSString *const PASTEBOARD_TYPE_TEXTURE = @"com.cocosbuilder.texture";
static NSString *const PASTEBOARD_TYPE_TEMPLATE = @"com.cocosbuilder.template";
static NSString *const PASTEBOARD_TYPE_CCB = @"com.cocosbuilder.ccb";
static NSString *const PASTEBOARD_TYPE_PLUGINNODE = @"com.cocosbuilder.PlugInNode";
static NSString *const PASTEBOARD_TYPE_WAVE = @"com.cocosbuilder.wav";
static NSString *const PASTEBOARD_TYPE_JOINTBODY = @"com.cocosbuilder.jointBody";
static NSString *const PASTEBOARD_TYPE_EFFECTSPRITE = @"com.cocosbuilder.effectSprite";

static NSString *const ORIGINAL_NODE_POINTER_KEY = @"srcNode";
static NSString *const ORIGINAL_NODE_KEY = @"originalNode";
static NSString *const COPY_NODE_KEY = @"copyNode";

static SequencerHandler* sharedSequencerHandler;

@implementation SequencerHandler

@synthesize dragAndDropEnabled;
@synthesize currentSequence;
@synthesize scrubberSelectionView;
@synthesize timeDisplay;
@synthesize outlineHierarchy;
@synthesize timeScaleSlider;
@synthesize scroller;
@synthesize scrollView;
@synthesize contextKeyframe;
@synthesize loopPlayback;

#pragma mark Init and singleton object

- (id) initWithOutlineView:(NSOutlineView*)view
{
    self = [super init];
    if (!self) return NULL;

    sharedSequencerHandler = self;
    
    appDelegate = [AppDelegate appDelegate];
    outlineHierarchy = view;
    
    [outlineHierarchy setDataSource:self];
    [outlineHierarchy setDelegate:self];
    [outlineHierarchy reloadData];

	[outlineHierarchy registerForDraggedTypes:@[PASTEBOARD_TYPE_NODE,
			PASTEBOARD_TYPE_TEXTURE,
			PASTEBOARD_TYPE_TEMPLATE,
			PASTEBOARD_TYPE_CCB,
			PASTEBOARD_TYPE_PLUGINNODE,
			PASTEBOARD_TYPE_WAVE,
			PASTEBOARD_TYPE_JOINTBODY,
			PASTEBOARD_TYPE_EFFECTSPRITE]];

	[[[outlineHierarchy outlineTableColumn] dataCell] setEditable:YES];
    
    return self;
}

+ (SequencerHandler*) sharedHandler
{
    return sharedSequencerHandler;
}

#pragma mark Handle Scale slider

- (void) setTimeScaleSlider:(NSSlider *)tss
{
    if (tss != timeScaleSlider)
    {
        timeScaleSlider = tss;
        
        [timeScaleSlider setTarget:self];
        [timeScaleSlider setAction:@selector(timeScaleSliderUpdated:)];
    }
}

- (void) timeScaleSliderUpdated:(id)sender
{
    currentSequence.timelineScale = timeScaleSlider.floatValue;
}

- (void) updateScaleSlider
{
    if (!currentSequence)
    {
        timeScaleSlider.doubleValue = kCCBDefaultTimelineScale;
        [timeScaleSlider setEnabled:NO];
        return;
    }

    [timeScaleSlider setEnabled:YES];
    timeScaleSlider.floatValue = currentSequence.timelineScale;
}

#pragma mark Handle scroller

- (float) visibleTimeArea
{
    NSTableColumn* column = [outlineHierarchy tableColumnWithIdentifier:@"sequencer"];
    return (float) ((column.width - 2*TIMELINE_PAD_PIXELS)/currentSequence.timelineScale);
}

- (float) maxTimelineOffset
{
    float visibleTime = [self visibleTimeArea];
    return MAX(currentSequence.timelineLength - visibleTime, 0);
}

- (void) updateScroller
{
    float visibleTime = [self visibleTimeArea];
    float maxTimeScroll = currentSequence.timelineLength - visibleTime;
    
    float proportion = visibleTime/currentSequence.timelineLength;

    scroller.knobProportion = proportion;
    scroller.doubleValue = currentSequence.timelineOffset / maxTimeScroll;
	[scroller setEnabled:(proportion < 1)];
}

- (void) updateScrollerToShowCurrentTime
{
    float visibleTime = [self visibleTimeArea];
    float maxTimeScroll = [self maxTimelineOffset];
    float timelinePosition = currentSequence.timelinePosition;
    if (maxTimeScroll > 0)
    {
        float minVisibleTime = (float) (scroller.doubleValue*(currentSequence.timelineLength-visibleTime));
        float maxVisibleTime = (float) (scroller.doubleValue*(currentSequence.timelineLength-visibleTime) + visibleTime);
        
        if (timelinePosition < minVisibleTime) {
            scroller.doubleValue = timelinePosition/(currentSequence.timelineLength-visibleTime);
            currentSequence.timelineOffset = (float) (scroller.doubleValue * (currentSequence.timelineLength - visibleTime));
        } else if (timelinePosition > maxVisibleTime) {
            scroller.doubleValue = (timelinePosition-visibleTime)/(currentSequence.timelineLength-visibleTime);
            currentSequence.timelineOffset = (float) (scroller.doubleValue * (currentSequence.timelineLength - visibleTime));
        }
    }
}

- (void) setScroller:(NSScroller *)s
{
    if (s != scroller)
    {
        scroller = s;
        
        [scroller setTarget:self];
        [scroller setAction:@selector(scrollerUpdated:)];
        
        [self updateScroller];
    }
}

- (void) scrollerUpdated:(id)sender
{
    float newOffset = currentSequence.timelineOffset;
    float visibleTime = [self visibleTimeArea];
    
    switch ([scroller hitPart]) {
        case NSScrollerNoPart:
            break;
        case NSScrollerDecrementPage:
            newOffset -= 300 / currentSequence.timelineScale;
            break;
        case NSScrollerKnob:
            newOffset = (float) (scroller.doubleValue * (currentSequence.timelineLength - visibleTime));
            break;
        case NSScrollerIncrementPage:
            newOffset += 300 / currentSequence.timelineScale;
            break;
        case NSScrollerDecrementLine:
            newOffset -= 20 / currentSequence.timelineScale;
            break;
        case NSScrollerIncrementLine:
            newOffset += 20 / currentSequence.timelineScale;
            break;
        case NSScrollerKnobSlot:
            newOffset = (float) (scroller.doubleValue * (currentSequence.timelineLength - visibleTime));
            break;
        default:
            break;
    }

    currentSequence.timelineOffset = newOffset;
}

#pragma mark Outline view

- (void) updateOutlineViewSelection
{
	[self expandSelectedNodes];

 	[outlineHierarchy selectRowIndexes:[self createSelectionIndexes] byExtendingSelection:NO];
}

- (NSIndexSet *)createSelectionIndexes
{
	NSMutableIndexSet* indexes = [NSMutableIndexSet indexSet];

	for (CCNode* selectedNode in appDelegate.selectedNodes)
    {
		NSUInteger row = (NSUInteger)[outlineHierarchy rowForItem:selectedNode];
		[indexes addIndex:row];
    }
	return indexes;
}

- (void)expandSelectedNodes
{
	if (appDelegate.selectedNodes.count == 0)
	{
		return;
	}

	SceneGraph *sceneGraph = [SceneGraph instance];
	CCNode* node = [appDelegate.selectedNodes objectAtIndex:0];

	if(node.plugIn.isJoint)
    {
         [outlineHierarchy expandItem:sceneGraph.joints];
    }
    else
    {
		[self expandParentsOfSelectedNodes:sceneGraph node:node];
	}
}

- (void)expandParentsOfSelectedNodes:(SceneGraph *)sceneGraph node:(CCNode *)node
{
	NSMutableArray *nodesToExpand = [NSMutableArray array];
	while ((node != sceneGraph.rootNode
			|| node != sceneGraph.joints.node)
		   && node != NULL)
	{
		[nodesToExpand insertObject:node atIndex:0];
		node = node.parent;
	}
	for (NSUInteger i = 0; i < [nodesToExpand count]; i++)
	{
		node = [nodesToExpand objectAtIndex:i];
		[outlineHierarchy expandItem:node.parent];
	}
}

#pragma mark -
#pragma mark Data Source Delegate
#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    
    if ([[SceneGraph instance] rootNode] == NULL) return 0;
	
	if (item == nil)
	{
		const NSUInteger itemCount = 4;
		
		// hide "Joints" item in Sprite Kit projects (assumes "Joints" is the last item in the outline view)
		if ([AppDelegate appDelegate].projectSettings.engine == CCBTargetEngineSpriteKit)
		{
			return (itemCount - 1);
		}
		return itemCount;
	}
    
    if([item isKindOfClass:[SequencerJoints class]])
    {
        SequencerJoints * joints = item;
        return [joints.all count];
    }

	CCNode *node = (CCNode *)item;
    return [[node children] count];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (item == nil) return YES;
    
    if ([item isKindOfClass:[SequencerChannel class]])
    {
        return NO;
    }
    
    if([item isKindOfClass:[SequencerJoints class]])
    {
        SequencerJoints * joints = item;
        return [joints.all count] > 0;
    }
    
    CCNode* node = (CCNode*)item;
    NodeInfo* info = node.userObject;
    PlugInNode*plugInInfo = info.plugIn;

	if (([[node children] count] == 0)
		|| !plugInInfo.canHaveChildren
		|| plugInInfo.isJoint)
	{
		return NO;
	}

	return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    SceneGraph *sceneGraph = [SceneGraph instance];

    if (item == NULL)
    {
		switch (index)
		{
			case 0 : return currentSequence.callbackChannel;
			case 1 : return currentSequence.soundChannel;
			case 2 : return sceneGraph.rootNode;
			case 3 : return sceneGraph.joints;
			default:
				NSAssert(NO, @"Index %li not supported", index);
		}
	}
    
    if([item isKindOfClass:[SequencerJoints class]])
    {
        return sceneGraph.joints.all[(NSUInteger) index];
    }

    CCNode* node = (CCNode*)item;
    return [[node children] objectAtIndex:(NSUInteger) index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item == nil)
	{
		return @"Root";
	}

	CCNode* node = item;
    
    if ([item isKindOfClass:[SequencerChannel class]])
    {
        SequencerChannel* channel = item;
        return channel.displayName;
    }
    
    if([item isKindOfClass:[SequencerJoints class]])
    {
        if ([tableColumn.identifier isEqualToString:@"hidden"])
        {
            SequencerJoints * joints = (SequencerJoints*)item;
            return  @(joints.node.hidden);            
        }
        
        if ([tableColumn.identifier isEqualToString:@"locked"])
        {
            SequencerJoints * joints = (SequencerJoints*)item;
            return  @(joints.node.locked);
        }
        
        
        return  @"Joints";
    }
    
    if ([tableColumn.identifier isEqualToString:@"sequencer"])
    {
        return @"";
    }
    
    if ([tableColumn.identifier isEqualToString:@"hidden"])
    {
        return @(node.hidden);
    }
    
    if ([tableColumn.identifier isEqualToString:@"locked"])
    {
        //only joints inherit their locked state from the root joint object.
        if(node.plugIn.isJoint)
        {
            if(node.parent.locked)
            {
                return @(YES);
            }
        }
        
        return @(node.locked);
    }
    
    return node.displayName;
}

-(void)willSetObjectValueJoint:(NSOutlineView *)outlineView objectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if([tableColumn.identifier isEqualToString:@"hidden"])
    {
		
		[appDelegate willChangeValueForKey:@"showJoints"];
        bool hidden = [(NSNumber*)object boolValue];
        SequencerJoints * joints = (SequencerJoints*)item;
        joints.node.hidden = hidden;
        [outlineView reloadItem:joints reloadChildren:YES];
		[appDelegate didChangeValueForKey:@"showJoints"];
        return;
    }
    
    if([tableColumn.identifier isEqualToString:@"locked"])
    {
        bool locked = [(NSNumber*)object boolValue];
        SequencerJoints * joints = (SequencerJoints*)item;
        joints.node.locked = locked;
        [outlineView reloadItem:joints reloadChildren:YES];
        return;
    }
}


- (void) outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  
    if([item isKindOfClass:[SequencerJoints class]])
    {
        [self willSetObjectValueJoint:outlineView objectValue:object forTableColumn:tableColumn byItem:item];
        return;
    }
    
    //Normal node editing.
    
    CCNode* node = item;
    
    if([tableColumn.identifier isEqualToString:@"hidden"])
    {
        bool hidden = [(NSNumber*)object boolValue];
        
        node.hidden = hidden;
        [outlineView reloadItem:node reloadChildren:YES];
    }
    else if([tableColumn.identifier isEqualToString:@"locked"])
    {
        node.locked = [(NSNumber*)object boolValue];
        if([AppDelegate appDelegate].selectedNode == node)
        {
            [[AppDelegate appDelegate] updateInspectorFromSelection];
        }
    }
    else if (![object isEqualToString:node.displayName])
    {
        [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*nodeDisplayName"];
        node.displayName = object;
    }
}

- (BOOL)canItemBeDragged:(id)item
{
	SceneGraph *sceneGraph = [SceneGraph instance];

	if (![item isKindOfClass:[CCNode class]])
	{
		return NO;
	}

	CCNode* draggedNode = item;
	if (draggedNode == sceneGraph.rootNode)
	{
		return NO;
	}

	if (draggedNode.plugIn.isJoint)
	{
		return NO;
	}
	return YES;
}

- (BOOL)canItemsBeDragged:(NSArray *)items
{
	if (!dragAndDropEnabled)
	{
		return NO;
	}

	for (id item in items)
	{
		if ( ![self canItemBeDragged:item])
		{
			return NO;
		}
	}
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
	if ( ! [self canItemsBeDragged:items])
	{
		return NO;
	}

	NSData *clipboardData = [self serializeDraggedItemsForClipboard:items];
	[pasteboard setData:clipboardData forType:PASTEBOARD_TYPE_NODE];
    
    return YES;
}

- (NSData *)serializeDraggedItemsForClipboard:(NSArray *)items
{
	NSMutableArray *array = [NSMutableArray array];
	for (CCNode *node in items)
	{
		NSMutableDictionary *clipDict = [CCBWriterInternal dictionaryFromCCObject:node];
		[clipDict setObject:[NSNumber numberWithLongLong:(long long) node] forKey:ORIGINAL_NODE_POINTER_KEY];

		[array addObject:clipDict];
	}

    return [NSKeyedArchiver archivedDataWithRootObject:array];
}

- (NSArray *)deserializeDraggedObjects:(NSData *)data
{
	NSMutableArray *array = [NSMutableArray array];
	NSArray *clipboardArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];

	for (NSDictionary *dictionary in clipboardArray)
	{
		void *nodePtr = (void*)[[dictionary objectForKey:ORIGINAL_NODE_POINTER_KEY] longLongValue];
        CCNode *originalNode = (__bridge CCNode*)nodePtr;

		NSDictionary *node = @{
				COPY_NODE_KEY : [CCBReaderInternal nodeGraphFromDictionary:dictionary parentSize:CGSizeZero],
			ORIGINAL_NODE_KEY : originalNode
		};

		[array addObject:node];
	}

	return array;
}

- (BOOL)isMoveValidToTargetNode:(CCNode *)targetNode droppedNodes:(NSArray *)droppedNodes
{
	// Cannot move nodes into themselves
	if ([droppedNodes containsObject:targetNode])
	{
		return NO;
	}

	CCNode *parent = [targetNode parent];
	SceneGraph *sceneGraph = [SceneGraph instance];

	while (parent && parent != sceneGraph.rootNode)
	{
		for (CCNode *droppedNode in droppedNodes)
		{
			if (parent == droppedNode)
			{
				return NO;
			}
		}
		parent = [parent parent];
	}

	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)dropTarget proposedChildIndex:(NSInteger)index
{
	if (dropTarget == NULL)
	{
		return NSDragOperationNone;
	}

    NSPasteboard *pasteboard = [info draggingPasteboard];
    
    NSData* nodeData = [pasteboard dataForType:PASTEBOARD_TYPE_NODE];
    if (nodeData)
    {
		return [self validateDropForNodeData:dropTarget nodeData:nodeData];
	}

	if ([self dropContainsMultipleTypes:pasteboard])
	{
		return NSDragOperationNone;
	}
	////////////////////////////////////////////////////////
    NSArray * effectsData = [pasteboard propertyListsForType:PASTEBOARD_TYPE_EFFECTSPRITE];
    if(effectsData.count > 0)
    {
		return [self validateDropForEffectSprite:dropTarget index:index];
	}


	////////////////////////////////////////////////////////
    NSArray * jointsData = [pasteboard propertyListsForType:PASTEBOARD_TYPE_JOINTBODY];
    if(jointsData.count > 0)
    {
		return [self validateDropForJointsData:dropTarget index:index];
	}

	if([dropTarget isKindOfClass:[SequencerSoundChannel class]])
	{
		return [self validateDropForWaveFiles:info pasteboard:pasteboard];
	}

    if([dropTarget isKindOfClass:[SequencerSoundChannel class]]
	   || [dropTarget isKindOfClass:[SequencerCallbackChannel class]] )
    {
        return NSDragOperationNone;
    }
	////////////////////////////////////////////////////////
    NSArray* pbNodePlugIn = [pasteboard propertyListsForType:PASTEBOARD_TYPE_PLUGINNODE];
	if (pbNodePlugIn.count > 0)
    {
		return [self validateDropForPluginNodes:pbNodePlugIn[0] target:dropTarget];
	}
	
	////////////////////////////////////////////////////////
    
    //Default behavior for Joints is don't accept drag and drops.
    if([dropTarget isKindOfClass:[CCNode class]])
    {
        CCNode * node = dropTarget;
		if (node.plugIn.isJoint)
		{
			return NSDragOperationNone;
		}
	}
    
    if([dropTarget isKindOfClass:[SequencerJoints class]])
    {
        return NSDragOperationNone;
    }

    return NSDragOperationGeneric;
}

- (BOOL)dropContainsMultipleTypes:(NSPasteboard *)pasteboard
{
	// There is always one extra type added: com.cocosbuilder.RMResource
	return [[pasteboard types] count] > 2;
}

- (NSDragOperation)validateDropForPluginNodes:(NSDictionary*)pluginNodeDescription target:(id)dropTarget
{
	PlugInNode * pluginNode = [[PlugInManager sharedManager] plugInNodeNamed:pluginNodeDescription[@"nodeClassName"]];
	
	//If we're dropping a joint onto the Sequencer Joints object, all's good.
	if([dropTarget isKindOfClass:[SequencerJoints class]] && pluginNode.isJoint)
	{
		return NSDragOperationGeneric;
	}
	
	//If its some other undefined object type, its not good.
	if (![dropTarget isKindOfClass:[CCNode class]])
	{
		return NSDragOperationNone;
	}

	CCNode *node = dropTarget;
	
	//If the incoming plugin is a joint?
	if (pluginNode.isJoint)
	{
		//Allow dropping joints onto joints.
		if(node.plugIn.isJoint)
		{
			return NSDragOperationGeneric;
		}
		else
		{
			//Don't allow dropping joints onto general timeline nodes.
			return NSDragOperationNone;
		}
	}

	return NSDragOperationGeneric;
}

- (NSDragOperation)validateDropForWaveFiles:(id <NSDraggingInfo>)info pasteboard:(NSPasteboard *)pasteboard
{
	NSArray *waveFiles = [pasteboard propertyListsForType:PASTEBOARD_TYPE_WAVE];
	if(waveFiles.count == 0)
	{
		return NSDragOperationNone;
	}

	NSPoint mouseLocationInWindow = info.draggingLocation;
	NSPoint mouseLocation = [scrubberSelectionView convertPoint:mouseLocationInWindow fromView:[appDelegate.window contentView]];

	currentSequence.soundChannel.dragAndDropTimeStamp = [currentSequence positionToTime:(float) mouseLocation.x];
	currentSequence.soundChannel.needDragAndDropRedraw = YES;

	[scrubberSelectionView setNeedsDisplay:YES];

	return NSDragOperationGeneric;
}

- (NSDragOperation)validateDropForJointsData:(id)dropTarget index:(NSInteger)index
{
	if (index != -1)
	{
		return NSDragOperationNone;
	}

	if (![dropTarget isKindOfClass:[CCNode class]])
	{
		return NSDragOperationNone;
	}

	CCNode* node = dropTarget;
	if (!node.nodePhysicsBody)
	{
		return NSDragOperationNone;
	}

	return NSDragOperationGeneric;
}


- (NSDragOperation)validateDropForEffectSprite:(id)dropTarget index:(NSInteger)index
{
	if (index != -1)
	{
		return NSDragOperationNone;
	}
	
	if (![dropTarget isKindOfClass:[CCSprite class]])
	{
		return NSDragOperationNone;
	}
	
	return NSDragOperationGeneric;
}



- (NSDragOperation)validateDropForNodeData:(id)item nodeData:(NSData *)nodeData
{
	if (![item isKindOfClass:[CCNode class]])
	{
		return NSDragOperationNone;
	}
	else
	{
		CCNode *dropTarget = item;
		NSArray *droppedOriginalNodes = [self extractDroppedNodes:[self deserializeDraggedObjects:nodeData] withKey:ORIGINAL_NODE_KEY];
		if (dropTarget.plugIn.isJoint ||
			![self isMoveValidToTargetNode:dropTarget droppedNodes:droppedOriginalNodes])
		{
			return NSDragOperationNone;
		}

		return NSDragOperationGeneric;
	}
}

- (NSArray *)extractDroppedNodes:(NSArray *)droppedNodes withKey:(NSString *)key
{
	NSMutableArray *result = [NSMutableArray array];
	for (NSDictionary *dict in droppedNodes)
	{
		CCNode *node = dict[key];
		[result addObject:node];
	}
	return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    
    NSData *clipData = [pasteboard dataForType:PASTEBOARD_TYPE_NODE];
    if (clipData)
    {
		return [self acceptDropForNodeType:item index:index clipData:clipData];
	}
    
    BOOL addedObject = NO;

	// accept methods may return NO so boolean OR applied, we don't want to override a YES
	// TODO: aren't these cases exclusive so a return would be feasible?
	addedObject = [self acceptDropForTexture:item pasteboard:pasteboard] || addedObject;

	addedObject = [self acceptDropForWaveFiles:info pasteboard:pasteboard] || addedObject;

	addedObject = [self acceptDropForCCBFiles:item pasteboard:pasteboard] || addedObject;

	addedObject = [self acceptDropForPluginNodes:item index:index pasteboard:pasteboard] || addedObject;

	addedObject = [self acceptDropForJointBodies:item pasteboard:pasteboard] || addedObject;
	
	addedObject = [self acceptDropForEffectSprite:item pasteboard:pasteboard] || addedObject;
	
	return addedObject;
}



- (BOOL)acceptDropForEffectSprite:(id)item pasteboard:(NSPasteboard *)pasteboard
{
	BOOL addedObject = NO;
	NSArray* pbEffectSprite = [pasteboard propertyListsForType:PASTEBOARD_TYPE_EFFECTSPRITE];
	for (NSDictionary* dict in pbEffectSprite)
    {
        
		addedObject = YES;
    }
	return addedObject;
}


- (BOOL)acceptDropForJointBodies:(id)item pasteboard:(NSPasteboard *)pasteboard
{
	BOOL addedObject = NO;
	NSArray* pbJointBodys = [pasteboard propertyListsForType:PASTEBOARD_TYPE_JOINTBODY];
	for (NSDictionary* dict in pbJointBodys)
    {
        NSUInteger uuid = [dict[@"uuid"] unsignedIntegerValue];
        JointHandleType type = [dict[@"bodyIndex"]integerValue];
        
        CCBPhysicsJoint * joint = [[SceneGraph instance].joints.all findFirst:^BOOL(CCBPhysicsJoint * lJoint, int idx) {
            return lJoint.UUID == uuid;
        }];
        
        NSString * propertyName = [CCBPhysicsJoint convertBodyTypeToString:type];
        [joint setValue:item forKey:propertyName];
        [[AppDelegate appDelegate] refreshProperty:propertyName];

		addedObject = YES;
    }
	return addedObject;
}

- (BOOL)acceptDropForPluginNodes:(id)item index:(NSInteger)index pasteboard:(NSPasteboard *)pasteboard
{
	BOOL addedObject = NO;;
	NSArray* pbNodePlugIn = [pasteboard propertyListsForType:PASTEBOARD_TYPE_PLUGINNODE];
	for (NSDictionary* dict in pbNodePlugIn)
    {
		//Add joints differently.
		PlugInNode * pluginNode = [[PlugInManager sharedManager] plugInNodeNamed:dict[@"nodeClassName"]];
		if(pluginNode.isJoint)
		{
			//Default position is near the root nodes position.
			CGPoint point = [[CocosScene cocosScene].rootNode.parent convertToWorldSpace:[CocosScene cocosScene].rootNode.position];
			
			//If we're dropping it on another joints, place it near it.
			if([item isKindOfClass:[CCNode class]])
			{
				CCNode * node = (CCNode*)item;
				point = [node.parent convertToWorldSpaceAR:node.position];

			}
			//But don't place it directly on top.
			point = ccpAdd(point, ccp(5.0f,5.0f));
			
			[appDelegate dropAddPlugInNodeNamed:dict[@"nodeClassName"] at: point];
		}
		else //Default add node.
		{
			
			[appDelegate dropAddPlugInNodeNamed:[dict objectForKey:@"nodeClassName"] parent:item index:index];
		}
        addedObject = YES;
    }
	return addedObject;
}

- (BOOL)acceptDropForCCBFiles:(id)item pasteboard:(NSPasteboard *)pasteboard
{
	BOOL addedObject = NO;;
	NSArray* pbCCBs = [pasteboard propertyListsForType:PASTEBOARD_TYPE_CCB];
	for (NSDictionary* dict in pbCCBs)
    {
        [appDelegate dropAddCCBFileNamed:[dict objectForKey:@"ccbFile"] at:ccp(0, 0) parent:item];
        addedObject = YES;
    }
	return addedObject;
}

- (BOOL)acceptDropForWaveFiles:(id <NSDraggingInfo>)info pasteboard:(NSPasteboard *)pasteboard
{
	BOOL addedObject = NO;
	NSArray* pbWavs = [pasteboard propertyListsForType:PASTEBOARD_TYPE_WAVE];
	for (NSDictionary* dict in pbWavs)
    {
        NSPoint mouseLocationInWindow = info.draggingLocation;
        NSPoint mouseLocation = [scrubberSelectionView convertPoint:mouseLocationInWindow fromView:[appDelegate.window contentView]];

        //Create Keyframe
        SequencerKeyframe * keyFrame = [currentSequence.soundChannel addDefaultKeyframeAtTime:[currentSequence positionToTime:(float) mouseLocation.x]];
        NSMutableArray* newArr = [NSMutableArray arrayWithArray:keyFrame.value];
        [newArr replaceObjectAtIndex:kSoundChannelKeyFrameName withObject:dict[@"wavFile"]];
        keyFrame.value = newArr;

        addedObject = YES;
    }
	return addedObject;
}

- (BOOL)acceptDropForTexture:(id)parent pasteboard:(NSPasteboard *)pasteboard
{
	BOOL addedObject = NO;
	NSArray* pbTextures = [pasteboard propertyListsForType:PASTEBOARD_TYPE_TEXTURE];
	for (NSDictionary* dict in pbTextures)
    {
		[appDelegate dropAddSpriteNamed:[dict objectForKey:@"spriteFile"] inSpriteSheet:[dict objectForKey:@"spriteSheetFile"] at:ccp(0, 0) parent:parent];
        addedObject = YES;
    }
	return addedObject;
}

- (BOOL)acceptDropForNodeType:(id)item index:(NSInteger)index clipData:(NSData *)clipData
{
	NSArray *nodes = [self deserializeDraggedObjects:clipData];
	for (NSDictionary *node in nodes)
		{
			CCNode *originalNode = node[ORIGINAL_NODE_KEY];
			CCNode *nodeCopy = node[COPY_NODE_KEY];

			if (![appDelegate addCCObject:nodeCopy toParent:item atIndex:index])
			{
				return NO;
			}

			[appDelegate deleteNode:originalNode];
		}

	[appDelegate setSelectedNodes:[self extractDroppedNodes:nodes withKey:COPY_NODE_KEY]];

	[SceneGraph fixupReferences];

	return YES;
}

#pragma mark -
#pragma mark View Delegate
#pragma mark -

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{    
    NSIndexSet* indexes = [outlineHierarchy selectedRowIndexes];
    NSMutableArray* selectedNodes = [NSMutableArray array];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop)
	{
        id item = [outlineHierarchy itemAtRow:index];

        if (![item isKindOfClass:[SequencerChannel class]] && ![item isKindOfClass:[SequencerJoints class]])
        {
            CCNode* node = item;
            [selectedNodes addObject:node];
        }
        if([item isKindOfClass:[SequencerJoints class]])
        {
            SequencerJoints * joints = (SequencerJoints *)item;
            [selectedNodes addObject:joints.node];
        }
    }];
    
    appDelegate.selectedNodes = selectedNodes;
    
    [appDelegate updateInspectorFromSelection];
    [[CocosScene cocosScene] selectionUpdated];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    if([notification.userInfo[@"NSObject"] isKindOfClass:[SequencerJoints class]])
    {
        return;
    }

    CCNode* node = [[notification userInfo] objectForKey:@"NSObject"];
    [node setExtraProp:[NSNumber numberWithBool:NO] forKey:@"isExpanded"];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
    if([notification.userInfo[@"NSObject"] isKindOfClass:[SequencerJoints class]])
    {
        return;
    }
    
    CCNode* node = [[notification userInfo] objectForKey:@"NSObject"];
    [node setExtraProp:[NSNumber numberWithBool:YES] forKey:@"isExpanded"];
}

-(void)setChildrenHidden:(bool)hidden withChildren:(NSArray*)children
{
    for(CCNode * child in children)
    {
        child.hidden = hidden;
        [self setChildrenHidden:hidden withChildren:child.children];
    }
}

- (BOOL) outlineView:(NSOutlineView *)outline shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if([tableColumn.identifier isEqualToString:@"hidden"])
    {
        return NO;
    }
    else if([tableColumn.identifier isEqualToString:@"locked"])
    {
        return NO;
    }
    else
    {
        [outline editColumn:0 row:[outline selectedRow] withEvent:[NSApp currentEvent] select:YES];
    }
    return YES;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if ([item isKindOfClass:[CCNode class]] ||[item isKindOfClass:[SequencerJoints class]])
        return YES;
    
    return NO;
}

- (CGFloat) outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    if ([item isKindOfClass:[SequencerCallbackChannel class]])
    {
        return kCCBSeqDefaultRowHeight;
    }
    else if ([item isKindOfClass:[SequencerSoundChannel class]])
    {
        SequencerSoundChannel * channel = item;
        if(!channel.isEpanded)
            return kCCBSeqDefaultRowHeight;
        else
            return kCCBSeqAudioRowHeight;//+1;
    }
    else if([item isKindOfClass:[SequencerJoints class]])
    {
        return kCCBSeqDefaultRowHeight;
    }
    
    CCNode* node = item;
    if (node.seqExpanded)
    {
        return kCCBSeqDefaultRowHeight * ([[node.plugIn animatablePropertiesForNode:node] count]);
    }
    else
    {
        return kCCBSeqDefaultRowHeight;
    }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setImagePosition:NSImageAbove];
}

- (void) outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if([item isKindOfClass:[SequencerJoints class]])
    {
		[self willDisplayJointCells:cell tableColumn:tableColumn];
		return;
    }
    
    if ([item isKindOfClass:[SequencerChannel class]])
    {
		[self willDisplayChannelCell:cell tableColumn:tableColumn item:item];
		return;
	}
    
    CCNode* node = item;
    BOOL isRootNode = node == [CocosScene cocosScene].rootNode;
    
    if([tableColumn.identifier isEqualToString:@"hidden"])
    {
		[self willDisplayHiddenCell:cell node:node];
	}

    if([tableColumn.identifier isEqualToString:@"locked"])
    {
		[self willDisplayLockedCell:cell node:node];
	}

    if ([tableColumn.identifier isEqualToString:@"expander"])
    {
		[self willDisplayExpanderCell:cell node:node isRootNode:isRootNode];
	}
    else if ([tableColumn.identifier isEqualToString:@"structure"])
    {
		[self willDisplayStructurerCell:cell node:node];
	}
    else if ([tableColumn.identifier isEqualToString:@"sequencer"])
    {
		[self willDisplaySequencerCell:cell node:node];
	}
}

- (void)willDisplaySequencerCell:(id)cell node:(CCNode *)node
{
	SequencerCell* seqCell = cell;
	seqCell.node = node;
}

- (void)willDisplayStructurerCell:(id)cell node:(CCNode *)node
{
	SequencerStructureCell* strCell = cell;
	strCell.node = node;
}

- (void)willDisplayExpanderCell:(id)cell node:(CCNode *)node isRootNode:(BOOL)isRootNode
{
	SequencerExpandBtnCell* expCell = cell;
	expCell.isExpanded = node.seqExpanded;
	expCell.canExpand = (!isRootNode && !node.plugIn.isJoint);
	expCell.node = node;
}

- (void)willDisplayLockedCell:(id)cell node:(CCNode *)node
{
	SequencerLockedCell * buttonCell = cell;
	[buttonCell setTransparent:NO];
	buttonCell.node = node;
    
    if(node.plugIn.isJoint)
    {   
        if(node.parent.locked)
        {
            buttonCell.status = LockedButtonStatus_SetNotEnabled;
        }
        else
        {

            buttonCell.status = node.locked ? LockedButtonStatus_Set : LockedButtonStatus_NoSet;
        }
    }
    else
    {
        buttonCell.status = node.locked ? LockedButtonStatus_Set : LockedButtonStatus_NoSet;
    }
}

- (void)willDisplayHiddenCell:(id)cell node:(CCNode *)node
{
	SequencerButtonCell * buttonCell = cell;
	buttonCell.node = node;
	[buttonCell setTransparent:NO];

	if (node.parentHidden)
	{
		[buttonCell setEnabled:NO];
	}
	else
	{
		[buttonCell setEnabled:YES];
	}
}

- (void)willDisplayChannelCell:(id)cell tableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([tableColumn.identifier isEqualToString:@"expander"])
	{
		SequencerExpandBtnCell *expCell = cell;
		expCell.node = NULL;

		if ([item isKindOfClass:[SequencerCallbackChannel class]])
		{
			expCell.isExpanded = NO;
			expCell.canExpand = NO;
		}
		else if ([item isKindOfClass:[SequencerSoundChannel class]])
		{
			SequencerSoundChannel *soundChannel = item;

			expCell.isExpanded = soundChannel.isEpanded;
			expCell.canExpand = YES;
		}
	}
	else if ([tableColumn.identifier isEqualToString:@"structure"])
	{
		SequencerStructureCell *strCell = cell;
		strCell.node = NULL;
		strCell.drawHardLine = YES;
	}
	else if ([tableColumn.identifier isEqualToString:@"sequencer"])
	{
		SequencerCell *seqCell = cell;
		seqCell.node = NULL;

		if ([item isKindOfClass:[SequencerCallbackChannel class]])
		{
			seqCell.channel = (SequencerCallbackChannel *) item;
		}
		else if ([item isKindOfClass:[SequencerSoundChannel class]])
		{
			seqCell.channel = (SequencerSoundChannel *) item;
		}
	}
	else if ([tableColumn.identifier isEqualToString:@"locked"] ||
			 [tableColumn.identifier isEqualToString:@"hidden"])
	{
		SequencerButtonCell *buttonCell = cell;
		buttonCell.node = nil;

		if ([item isKindOfClass:[SequencerCallbackChannel class]] ||
			[item isKindOfClass:[SequencerSoundChannel class]])
		{
			[buttonCell setTransparent:YES];
		}
		else
		{
			[buttonCell setTransparent:NO];
		}

	}
	return;
}

- (void)willDisplayJointCells:(id)cell tableColumn:(NSTableColumn *)tableColumn
{
	if ([tableColumn.identifier isEqualToString:@"expander"])
	{
		SequencerExpandBtnCell *expCell = cell;
		expCell.node = [SceneGraph instance].joints.node;
		expCell.canExpand = NO;
	}

	if ([tableColumn.identifier isEqualToString:@"locked"])
    {
		SequencerLockedCell *buttonCell = cell;
		buttonCell.node = [SceneGraph instance].joints.node;
		[buttonCell setTransparent:NO];
        [buttonCell setEnabled:YES];
        buttonCell.status = [SceneGraph instance].joints.node.locked ? LockedButtonStatus_Set : LockedButtonStatus_NoSet;

    }
    
    if([tableColumn.identifier isEqualToString:@"hidden"])
	{
        SequencerButtonCell *buttonCell = cell;
		buttonCell.node = [SceneGraph instance].joints.node;
		[buttonCell setTransparent:NO];
        [buttonCell setEnabled:YES];
	}

	if ([tableColumn.identifier isEqualToString:@"structure"])
	{
		SequencerStructureCell *strCell = cell;
		strCell.drawHardLine = NO;
		strCell.node = NULL;
	}
}

- (void) updateExpandedForNode:(CCNode*)node
{
    if ([self outlineView:outlineHierarchy isItemExpandable:node])
    {
        bool expanded = [[node extraPropForKey:@"isExpanded"] boolValue];
        if (expanded) [outlineHierarchy expandItem:node];
        else [outlineHierarchy collapseItem:node];
        
        NSArray* childs = [node children];
        for (NSUInteger i = 0; i < [childs count]; i++)
        {
            CCNode* child = [childs objectAtIndex:i];
            [self updateExpandedForNode:child];
        }
    }
}

- (void) toggleSeqExpanderForRow:(int)row
{
    id item = [outlineHierarchy itemAtRow:row];
    
    if ([item isKindOfClass:[SequencerCallbackChannel class]])
    {
        return;
    }
    else if([item isKindOfClass:[SequencerSoundChannel class]])
    {
        SequencerSoundChannel * soundChannel = item;
        soundChannel.isEpanded = !soundChannel.isEpanded;
    }
    else if([item isKindOfClass:[SequencerJoints class]])
    {
        return;
    }
    else
    {
        CCNode* node = item;

		if ((node == [CocosScene cocosScene].rootNode && !node.seqExpanded)
			|| node.plugIn.isJoint)
		{
			return;
		}

		node.seqExpanded = !node.seqExpanded;
    }
    
    // Need to reload all data when changing heights of rows
    [outlineHierarchy reloadData];
}

#pragma mark Timeline

- (void) redrawTimeline:(BOOL) reload
{
    [scrubberSelectionView setNeedsDisplay:YES];

    NSString* displayTime = [currentSequence currentDisplayTime];
	if (!displayTime)
	{
		displayTime = @"00:00:00";
	}

	[timeDisplay setStringValue:displayTime];
    [self updateScroller];

	if (reload)
	{
		[outlineHierarchy reloadData];
	}
}

- (void) redrawTimeline
{
    [self redrawTimeline:YES];
}

#pragma mark Util

- (void) deleteSequenceId:(int)seqId
{
    // Delete any keyframes for the sequence
    [[CocosScene cocosScene].rootNode deleteSequenceId:seqId];
    
    // Delete any chained sequence references
    for (SequencerSequence* seq in [AppDelegate appDelegate].currentDocument.sequences)
    {
        if (seq.chainedSequenceId == seqId)
        {
            seq.chainedSequenceId = -1;
        }
    }
    
    [[AppDelegate appDelegate] updateTimelineMenu];
}

- (void) deselectKeyframesForNode:(CCNode*)node
{
    [node deselectAllKeyframes];
    
    // Also deselect keyframes of children
    for (CCNode* child in node.children)
    {
        [self deselectKeyframesForNode:child];
    }
}

- (void) deselectAllKeyframes
{
    [self deselectKeyframesForNode:[[CocosScene cocosScene] rootNode]];
    [currentSequence.soundChannel.seqNodeProp deselectKeyframes];
    [currentSequence.callbackChannel.seqNodeProp deselectKeyframes];
    
    [outlineHierarchy reloadData];
}

- (BOOL) deleteSelectedKeyframesForCurrentSequence
{
    BOOL didDelete = [[CocosScene cocosScene].rootNode deleteSelectedKeyframesForSequenceId:currentSequence.sequenceId];
    
    didDelete |= [currentSequence.callbackChannel.seqNodeProp deleteSelectedKeyframes];
    didDelete |= [currentSequence.soundChannel.seqNodeProp deleteSelectedKeyframes];
    
    if (didDelete)
    {
        [self redrawTimeline];
        [self updatePropertiesToTimelinePosition];
        [[AppDelegate appDelegate] updateInspectorFromSelection];
    }
    return didDelete;
}

- (void) deleteDuplicateKeyframesForCurrentSequence
{
    BOOL didDelete = [[CocosScene cocosScene].rootNode deleteDuplicateKeyframesForSequenceId:currentSequence.sequenceId];
    
    if (didDelete)
    {
        [self redrawTimeline];
        [self updatePropertiesToTimelinePosition];
        [[AppDelegate appDelegate] updateInspectorFromSelection];
    }
}

- (void) deleteKeyframesForCurrentSequenceAfterTime:(float)time
{
    [[CocosScene cocosScene].rootNode deleteKeyframesAfterTime:time sequenceId:currentSequence.sequenceId];
}

- (void) addSelectedKeyframesForChannel:(SequencerChannel*) channel ToArray:(NSMutableArray*)keyframes
{
    for (SequencerKeyframe* keyframe in channel.seqNodeProp.keyframes)
    {
        if (keyframe.selected)
        {
            [keyframes addObject:keyframe];
        }
    }
}

- (void) addSelectedKeyframesForNode:(CCNode*)node toArray:(NSMutableArray*)keyframes
{
    [node addSelectedKeyframesToArray:keyframes];
    
    // Also add selected keyframes of children
    for (CCNode* child in node.children)
    {
        [self addSelectedKeyframesForNode:child toArray:keyframes];
    }
}

- (NSArray*) selectedKeyframesForCurrentSequence
{
    NSMutableArray* keyframes = [NSMutableArray array];
    [self addSelectedKeyframesForNode:[[CocosScene cocosScene] rootNode] toArray:keyframes];
    [self addSelectedKeyframesForChannel:currentSequence.callbackChannel ToArray:keyframes];
    [self addSelectedKeyframesForChannel:currentSequence.soundChannel ToArray:keyframes];
    return keyframes;
}

- (SequencerSequence*) seqId:(int)seqId inArray:(NSArray*)array
{
    for (SequencerSequence* seq in array)
    {
        if (seq.sequenceId == seqId) return seq;
    }
    return NULL;
}

- (void) updatePropertiesToTimelinePositionForNode:(CCNode*)node sequenceId:(int)seqId localTime:(float)time
{
    [node updatePropertiesTime:time sequenceId:seqId];
    
    // Also deselect keyframes of children
    for (CCNode* child in node.children)
    {
        int childSeqId = seqId;
        float localTime = time;
        
        // Sub ccb files uses different sequence id:s
        NSArray* childSequences = [child extraPropForKey:@"*sequences"];
        int childStartSequence = [[child extraPropForKey:@"*startSequence"] intValue];
        
        if (childSequences && childStartSequence != -1)
        {
            childSeqId = childStartSequence;
            SequencerSequence* seq = [self seqId:childSeqId inArray:childSequences];
            
            while (localTime > seq.timelineLength && seq.chainedSequenceId != -1)
            {
                localTime -= seq.timelineLength;
                seq = [self seqId:seq.chainedSequenceId inArray:childSequences];
                childSeqId = seq.sequenceId;
            }
        }
        
        [self updatePropertiesToTimelinePositionForNode:child sequenceId:childSeqId localTime:localTime];
    }
}

- (void) updatePropertiesToTimelinePosition
{
    [self updatePropertiesToTimelinePositionForNode:[[CocosScene cocosScene] rootNode] sequenceId:currentSequence.sequenceId localTime:currentSequence.timelinePosition];
}

- (void) setCurrentSequence:(SequencerSequence *)seq
{
    if (seq != currentSequence)
    {
        currentSequence = seq;
        
        [outlineHierarchy reloadData];
        [[AppDelegate appDelegate] updateTimelineMenu];
        [self redrawTimeline];
        [self updatePropertiesToTimelinePosition];
        [[AppDelegate appDelegate] updateInspectorFromSelection];
        [self updateScaleSlider];
    }
}

- (void) menuSetSequence:(id)sender
{
    int seqId = [sender tag];
    
    SequencerSequence* seqSet = NULL;
    for (SequencerSequence* seq in [AppDelegate appDelegate].currentDocument.sequences)
    {
        if (seq.sequenceId == seqId)
        {
            seqSet = seq;
            break;
        }
    }
    
    self.currentSequence = seqSet;
}

- (void) menuSetChainedSequence:(id)sender
{
    int seqId = [sender tag];
    if (seqId != self.currentSequence.chainedSequenceId)
    {
        [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*chainedseqid"];
        self.currentSequence.chainedSequenceId = [sender tag];
        [[AppDelegate appDelegate] updateTimelineMenu];
    }
}

#pragma mark Easings

- (void) setContextKeyframeEasingType:(int) type
{
    if (!contextKeyframe) return;
    if (contextKeyframe.easing.type == type) return;
    
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:@"*keyframeeasing"];
    
    contextKeyframe.easing.type = type;
    [self redrawTimeline];
}

#pragma mark Adding keyframes

- (void) menuAddKeyframeNamed:(NSString*)prop
{
    CCNode* node = [AppDelegate appDelegate].selectedNode;
    if (!node) return;
    
    SequencerSequence* seq = self.currentSequence;
    
    [node addDefaultKeyframeForProperty:prop atTime: seq.timelinePosition sequenceId:seq.sequenceId];
    [self deleteDuplicateKeyframesForCurrentSequence];
    
    node.seqExpanded = YES;
}

- (BOOL) canInsertKeyframeNamed:(NSString*)prop
{
    CCNode* node = [AppDelegate appDelegate].selectedNode;

	if (!node || !prop || [node shouldDisableProperty:prop])
	{
		return NO;
	}

    return [[node.plugIn animatablePropertiesForNode:node] containsObject:prop];
}

#pragma mark Destructor

- (void) dealloc
{
    self.currentSequence = NULL;
}

@end
