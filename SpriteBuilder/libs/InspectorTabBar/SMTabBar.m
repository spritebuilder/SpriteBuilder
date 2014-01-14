//
//  SMTabBar.m
//  InspectorTabBar
//
//  Created by Stephan Michels on 30.01.12.
//  Copyright (c) 2012 Stephan Michels Softwareentwicklung und Beratung. All rights reserved.
//

#import "SMTabBar.h"
#import "SMTabBarItem.h"
#import "SMTabBarButtonCell.h"
#import "NSDictionary+SMKeyValueObserving.h"


#define SMTabBarButtonWidth 32.0f

@interface SMTabBar ()

@property (nonatomic, copy) NSArray *barButtons;

- (void)adjustSubviews;

@end

@implementation SMTabBar

static char SMObservationContext;

#pragma mark - Initialization / Deallocation

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        // add observer for properties
        [self addObserver:self forKeyPath:@"items" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:&SMObservationContext];
        [self addObserver:self forKeyPath:@"selectedItem" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:&SMObservationContext];
    }
    return self;
}

- (void)dealloc {
	SBLogSelf();
	
    // remove observer for properties
    [self removeObserver:self forKeyPath:@"items" context:&SMObservationContext];
    [self removeObserver:self forKeyPath:@"selectedItem" context:&SMObservationContext];
    
    // unbind button
    for (NSButton *button in self.barButtons) {
        [button unbind:@"image"];
        [button unbind:@"enabled"];
        [button unbind:@"toolTip"];
        [button unbind:@"keyEquivalent"];
        [button unbind:@"keyEquivalentModifierMask"];
    }
}

#pragma mark - Actions

-(void)selectBarButtonIndex:(NSInteger)index
{
    [self selectBarButton:self.barButtons[index]];
}

- (void)selectBarButton:(id)sender {
    // select a bar button
    
    NSUInteger itemIndex = [sender tag];
    SMTabBarItem *tabBarItem = [self.items objectAtIndex:itemIndex];
	if ([self.delegate respondsToSelector:@selector(tabBar:shouldSelectItem:)]) {
		BOOL shouldSelectItem = [self.delegate tabBar:self shouldSelectItem:tabBarItem];
        if (!shouldSelectItem) {
			return;
		}
    }
    if ([self.delegate respondsToSelector:@selector(tabBar:willSelectItem:)]) {
        [self.delegate tabBar:self willSelectItem:tabBarItem];
    }
    self.selectedItem = tabBarItem;
    if ([self.delegate respondsToSelector:@selector(tabBar:didSelectItem:)]) {
        [self.delegate tabBar:self didSelectItem:tabBarItem];
    }
}

#pragma mark - Private methods

- (void)updateButtons {
	// remove old buttons
	for (NSButton *button in self.barButtons) {
		[button removeFromSuperview];
		
		[button unbind:@"image"];
		[button unbind:@"enabled"];
		[button unbind:@"toolTip"];
		[button unbind:@"keyEquivalent"];
		[button unbind:@"keyEquivalentModifierMask"];
	}
	self.barButtons = nil;
	
	// add new buttons
	NSMutableArray *newBarButtons = [NSMutableArray arrayWithCapacity:[self.items count]];
	NSUInteger selectedItemIndex = [self.items indexOfObject:self.selectedItem];
	NSUInteger itemIndex = 0;
	for (SMTabBarItem *item in self.items) {
		NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, SMTabBarButtonWidth, NSHeight(self.bounds))];
		
		// add special button cell for the selected state
		button.cell = [[SMTabBarButtonCell alloc] init];
		
		// set properties of the button
		button.image = item.image;
		[button setEnabled:item.enabled];
		button.state = itemIndex == selectedItemIndex ? NSOnState : NSOffState;
		button.tag = itemIndex;
		button.action = @selector(selectBarButton:);
		button.target = self;
		[button sendActionOn:NSLeftMouseDownMask];
		[self addSubview:button];
		
		// bind button properties to the item properties
		[button bind:@"image" toObject:item withKeyPath:@"image" options:nil];
		[button bind:@"enabled" toObject:item withKeyPath:@"enabled" options:nil];
		[button bind:@"toolTip" toObject:item withKeyPath:@"toolTip" options:nil];
		[button bind:@"keyEquivalent" toObject:item withKeyPath:@"keyEquivalent" options:nil];
		[button bind:@"keyEquivalentModifierMask" toObject:item withKeyPath:@"keyEquivalentModifierMask" options:nil];
		
		[newBarButtons addObject:button];
		
		itemIndex++;
	}
	self.barButtons = newBarButtons;
	
	// re-layout buttons
	[self adjustSubviews];
	
	// pre-select first button
	if (![self.items containsObject:self.selectedItem]) {
		self.selectedItem = [self.items count] > 0 ? [self.items objectAtIndex:0] : nil;
	}
}

- (void)updateButtonState {
	// update button states if the corresponding item is selected
	NSUInteger selectedItemIndex = [self.items indexOfObject:self.selectedItem];
	NSUInteger buttonIndex = 0;
	for (NSButton *button in self.barButtons) {
		button.state = buttonIndex == selectedItemIndex ? NSOnState : NSOffState;
		buttonIndex++;
	}
}

#pragma mark - Layout subviews

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
	[super resizeSubviewsWithOldSize:oldBoundsSize];
	[self adjustSubviews];
}

- (void)adjustSubviews {
    // layout subviews
    NSUInteger numberOfButtons = [self.barButtons count];
    CGFloat completeWidth = numberOfButtons * SMTabBarButtonWidth;
    CGFloat offset = floorf((NSWidth(self.bounds) - completeWidth) / 2.0f);
    for (NSButton *button in self.barButtons) {
        button.frame = NSMakeRect(offset, NSMinY(self.bounds), SMTabBarButtonWidth, NSHeight(self.bounds));
        offset += SMTabBarButtonWidth;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != &SMObservationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if (![change keyValueChanged]) {
        return;
    }
	
    if ([keyPath isEqualToString:@"items"]) {
        [self updateButtons];
    } else if ([keyPath isEqualToString:@"selectedItem"]) {
        [self updateButtonState];
    }
}

@end
