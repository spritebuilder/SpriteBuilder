//
//  InspectorEffectControl.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "InspectorEffectControl.h"
#import "AppDelegate.h"
#import "MainWindow.h"
#import "EffectViewController.h"
#import "EffectsManager.h"
#import "MiscConstants.h"


@interface InspectorEffectControl ()
{
	NSMutableArray * viewControllers;
}
@property (weak) IBOutlet NSTableView *tableView;

@end


@implementation InspectorEffectControl

- (id)initWithSelection:(CCNode*)aSelection andPropertyName:(NSString*)aPropertyName andDisplayName:(NSString*)aDisplayName andExtra:(NSString*)anExtra
{
	NSAssert([aSelection conformsToProtocol:@ protocol(CCEffectNodeProtocol)], @"Must conform to protocol");
	return [super initWithSelection:aSelection andPropertyName:aPropertyName andDisplayName:aDisplayName andExtra:anExtra];
}

- (id<CCEffectNodeProtocol>)effectNode
{
	return (id<CCEffectNodeProtocol>)selection;
}

- (IBAction)handleRemoveButton:(id)sender
{
    [self removeSelectedEffect];
}

- (void)removeSelectedEffect
{
    if([self.tableView selectedRow] >=0)
	{
		NSInteger row = [self.tableView selectedRow];
		CCEffect<EffectProtocol> *effect = [self.effectNode effects][(NSUInteger) row];

        [[AppDelegate appDelegate] saveUndoState];
		[self.effectNode removeEffect:effect];

		[self refresh];
	}
}

- (IBAction)handleAddButton:(id)sender
{
    NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Effects"];
    menu.font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];

    NSArray* effects = [EffectsManager effects];
    int group = 0;
    for (EffectDescription* effect in effects)
    {
        if (effect.group != group)
        {
            // Add separator
            NSMenuItem* separator = [NSMenuItem separatorItem];

            [menu addItem:separator];
            group = effect.group;
        }

        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:effect.title action:@selector(handleAddEffect:) keyEquivalent:@""];
        item.target = self;
        item.representedObject = effect;

        [menu addItem:item];
    }

    [menu popUpMenuPositioningItem:[menu itemAtIndex:0] atLocation:NSMakePoint(0, 15) inView:sender];
}

- (void) handleAddEffect:(id)sender
{
    NSMenuItem* item = sender;
    EffectDescription* effect = item.representedObject;

    [[AppDelegate appDelegate] saveUndoState];
    [[self effectNode] addEffect:[effect constructDefault]];
    [self refresh];
}

- (void) willBeAdded
{
	[self refresh];
}

- (void)refresh
{
	[viewControllers removeAllObjects];
	viewControllers = [NSMutableArray new];

	NSArray * effects = [[self effectNode] effects];

	for (NSUInteger i = 0; i < effects.count; i++)
	{
		EffectDescription * effectDescription = [[self effectNode] effectDescriptors][i];
		id<EffectProtocol> effect =  [self.effectNode effects][i];

		Class viewControllerClass = NSClassFromString(effectDescription.viewController);
		EffectViewController * vc = [((EffectViewController*)[viewControllerClass alloc]) initWithNibName:effectDescription.viewController bundle:[NSBundle mainBundle]];

		vc.effect =	effect;
		[viewControllers addObject:vc];
	}

    [_addEffectButton setEnabled:(effects.count < EFFECTS_MAXIMUM_PER_NODE)];
    [_removeEffectButton setEnabled:effects.count > 0];

    [self.tableView reloadData];
}


#pragma mark Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return viewControllers.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [[self effectNode] effectDescriptors][(NSUInteger) row];
}


#pragma mark View Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	int row = self.tableView.selectedRow;

    for (NSUInteger i = 0; i < viewControllers.count; i++)
    {
		EffectViewController * viewController = viewControllers[i];
		viewController.highlight = i == row;
	}
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [(NSViewController*)viewControllers[(NSUInteger) row] view];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSView * effectView = [(NSViewController*)viewControllers[(NSUInteger) row] view];
	return effectView.frame.size.height;
}

#pragma mark KeyboardEventHandler

- (void)keyDown:(NSEvent *)theEvent
{

}

- (void)keyUp:(NSEvent *)theEvent
{
    if([theEvent.characters characterAtIndex:0] == NSDeleteCharacter)
    {
       [self removeSelectedEffect];
    }
}

- (void)interpretKeyEvents:(NSArray *)eventArray
{

}


@end
