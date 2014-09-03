//
//  InspectorEffectControl.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "InspectorEffectControl.h"
#import "EffectSelectViewController.h"
#import "AppDelegate.h"
#import "MainWindow.h"
#import "EffectViewController.h"


@interface InspectorEffectControl ()
{
	NSMutableArray * viewControllers;
}
@property (weak) IBOutlet NSTableView *tableView;


@end

@implementation InspectorEffectControl


- (id) initWithSelection:(CCNode*)s andPropertyName:(NSString*)pn andDisplayName:(NSString*) dn andExtra:(NSString*)e
{
	NSAssert([s conformsToProtocol:@protocol(CCEffectNodeProtocol)], @"Must conform to protocol");
	return [super initWithSelection:s andPropertyName:pn andDisplayName:dn andExtra:e];
}

-(id<CCEffectNodeProtocol>)effectNode
{
	return (id<CCEffectNodeProtocol>)selection;
}

- (IBAction)handleRemoveButton:(id)sender
{
	if([self.tableView selectedRow] >=0)
	{
		NSInteger row = [self.tableView selectedRow];
		CCEffect<EffectProtocol> *effect = [self.effectNode effects][row];
		[self.effectNode removeEffect:effect];
		[self refresh];
	}
}

- (IBAction)handleAddButton:(id)sender
{

	EffectSelectViewController * vc =[[EffectSelectViewController alloc] initWithWindowNibName:@"EffectSelectViewController"];
	
	int success = [vc runModalSheetForWindow:[AppDelegate appDelegate].window];
	if(success)
	{
		EffectDescription * effectDescription = vc.selectedEffect;
		[[self effectNode] addEffect:[effectDescription constructDefault]];
		[self refresh];
	}

}


- (void) willBeAdded
{
	[self refresh];
}

-(void)refresh
{
	[viewControllers removeAllObjects];
	viewControllers = [NSMutableArray new];
	
	NSArray * effects = [[self effectNode] effects];
	
	for (int i = 0; i < effects.count; i++)
	{
		EffectDescription * effectDescription = [[self effectNode] effectDescriptors][i];
		id<EffectProtocol> effect =  [self.effectNode effects][i];
		
		Class viewControllerClass = NSClassFromString(effectDescription.viewController);
		EffectViewController * vc = [((EffectViewController*)[viewControllerClass alloc]) initWithNibName:effectDescription.viewController bundle:[NSBundle mainBundle]];
		
		vc.effect =	effect;
		[viewControllers addObject:vc];
	}
	
	[self.tableView reloadData];
}

#pragma mark Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return viewControllers.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [[self effectNode] effectDescriptors][row];
}

#pragma mark View Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	int row = self.tableView.selectedRow;
	
	for (int i=0; i < viewControllers.count; i++) {
		EffectViewController * viewController = viewControllers[i];
		viewController.highlight = i == row;
	}
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	
	return [(NSViewController*)viewControllers[row] view];
	
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSView * effectView = [(NSViewController*)viewControllers[row] view];
	return effectView.frame.size.height;
}

@end
