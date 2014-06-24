//
//  EffectSelectViewController.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "EffectSelectViewController.h"
#import "EffectDescriptionRowViewController.h"
#import "EffectsManager.h"

@interface EffectSelectViewController ()

@end

@implementation EffectSelectViewController

- (void) awakeFromNib
{
    [super awakeFromNib];
	
	[self.tableView setDoubleAction:@selector(onDoubleClick:)];
	
}


#pragma mark DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSArray * effects = [EffectsManager effects];
	return effects.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [EffectsManager effects][row];
}


#pragma mark View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	
	EffectDescription * effectDescription = [EffectsManager effects][row];

	EffectDescriptionRowViewController * effectRowView = [[EffectDescriptionRowViewController alloc] initWithNibName:@"EffectDescriptionRowViewController" bundle:[NSBundle mainBundle]];
	
	NSView * returnView = effectRowView.view;
	
	effectRowView.imageView.image = [NSImage imageNamed:effectDescription.imageName];
	effectRowView.descriptionLabel.stringValue = effectDescription.description;
	effectRowView.titleLabel.stringValue = effectDescription.title;
	
	return returnView;
	

}

-(void)onDoubleClick:(id)sender
{
	int row = [self.tableView clickedRow];
	NSArray * effects = [EffectsManager effects];
	if(row >= 0 && row < effects.count)
	{
		self.selectedEffect = effects[row];
		[self acceptSheet:self];
	}
}
@end

