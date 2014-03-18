//
//  PreferencesController.m
//  PreferenceWindow
//
//  Created by Nicky Weber on 17.03.14.
//  Copyright (c) 2014 Nicky Weber. All rights reserved.
//

#import "PreferencesController.h"


@interface PreferencesController()

@property (nonatomic) NSViewController *currentPreferenceViewController;

@end

@implementation PreferencesController

- (id)init
{
	self = [super initWithWindowNibName:@"Preferences"];

	if (self)
	{

	}
	return self;
}

- (void)windowDidLoad
{
	NSAssert(self.toolbar.items.count > 0, @"No toolbar items set, Preferences do not make sense without at least one item.");

	NSToolbarItem *toolbarItem = self.toolbar.items[0];
	[self switchToTab:toolbarItem.itemIdentifier firstAppearance:YES];
}

- (IBAction)changeTab:(id)sender
{
	NSToolbarItem *toolbarItem = sender;
	[self switchToTab:toolbarItem.itemIdentifier firstAppearance:NO];
}

- (void)switchToTab:(NSString *)itemIdentifier firstAppearance:(BOOL)firstAppearance
{
	[_toolbar setSelectedItemIdentifier:itemIdentifier];

	[self cleanUpContentView];

	NSViewController *viewController = [self createViewControllerWithToolbarIdentifier:itemIdentifier];
	self.currentPreferenceViewController = viewController;

	[self.window.contentView addSubview:viewController.view];
	[self resizeWindowToFitContentViewFirstAppearance:firstAppearance];
}

- (NSViewController *)createViewControllerWithToolbarIdentifier:(NSString *)toolbarItemIdentifier
{
	NSString *viewControllerclassName = [NSString stringWithFormat:@"%@ViewController", toolbarItemIdentifier];
	Class aClass = NSClassFromString(viewControllerclassName);
	NSAssert(aClass != nil, @"View controller class not found: %@", viewControllerclassName);
	NSViewController *viewController = [[aClass alloc] init];

	return viewController;
}

- (void)cleanUpContentView
{
	for (NSView *subView in [[self.window contentView] subviews])
	{
		NSLog(@"%@", subView);
		[subView removeFromSuperview];
	}
}

- (void)resizeWindowToFitContentViewFirstAppearance:(BOOL)firstAppearance
{	NSRect frame = [self.window frame];
	NSRect contentRect = [self.window.contentView frame];

	if (contentRect.size.height == self.currentPreferenceViewController.view.frame.size.height)
	{
		return;
	}

	// prevents flickering
	if (firstAppearance)
	{
		[self.window setIsVisible:NO];
	}

	CGFloat diff = [self.window.contentView frame].size.height - self.currentPreferenceViewController.view.frame.size.height;

	frame.size.height -= diff;
	frame.origin.y += diff;

	[self.window setFrame:frame display:NO animate:!firstAppearance];
	[self.window center];

	if (firstAppearance)
	{
		[self.window setIsVisible:YES];
	}
}

@end
