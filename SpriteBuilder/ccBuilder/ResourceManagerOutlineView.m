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

#import "ResourceManagerOutlineView.h"
#import "AppDelegate.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "ResourceManagerOutlineHandler.h"
#import "ProjectSettings.h"

@implementation ResourceManagerOutlineView

- (NSMenu*) menuForEvent:(NSEvent *)evt
{
	// It's called to draw a highlight on the right clicked item, the menu outlet of the outline view has to be just
	// set as well
	[super menuForEvent:evt];

	NSPoint clickedPoint = [self convertPoint:[evt locationInWindow] fromView:nil];
	int row = [self rowAtPoint:clickedPoint];

	id clickedItem = [self itemAtRow:row];

    NSMenu* menu = [AppDelegate appDelegate].menuContextResManager;
    menu.autoenablesItems = NO;
    
    NSArray* items = [menu itemArray];
    for (NSMenuItem* item in items)
    {
        item.tag = row;

        if (item.action == @selector(menuCreateSmartSpriteSheet:))
        {
            if ([clickedItem isKindOfClass:[RMResource class]]) {
                RMResource* clickedResource = clickedItem;
				[item setEnabled:NO];
                if (clickedResource.type == kCCBResTypeDirectory)
                {
                    RMDirectory* dir = clickedResource.data;

                    if (dir.isDynamicSpriteSheet)
                    {
                        item.title = @"Remove Smart Sprite Sheet";
                    }
                    else
                    {
                        item.title = @"Make Smart Sprite Sheet";
                    }

                    [item setEnabled:YES];
                }
            }
			else
			{
				[item setEnabled:NO];
			}
        }
        else if (item.action == @selector(menuEditSmartSpriteSheet:))
        {
            if ([clickedItem isKindOfClass:[RMResource class]]) {
                RMResource* clickedResource = clickedItem;
                [item setEnabled:NO];
                if (clickedResource.type == kCCBResTypeDirectory)
                {
                    RMDirectory* dir = clickedResource.data;
                    if (dir.isDynamicSpriteSheet)
                    {
                        [item setEnabled:YES];
                    }
                }
            }
        }
        else if (item.action == @selector(menuActionDelete:))
        {
            item.title = @"Delete";

			[item setEnabled:NO];
			if ([clickedItem isKindOfClass:[RMResource class]]
				&& [self isSomethingSelected])
			{
            	[item setEnabled:YES];
			}
        }
        else if (item.action == @selector(menuActionInterfaceFile:))
        {
            item.title = @"New File...";
        }
        else if (item.action == @selector(menuActionNewFolder:))
        {
            item.title = @"New Folder";
        }
        else if (item.action == @selector(menuOpenExternal:))
        {
			if ([clickedItem isKindOfClass:[RMResource class]])
			{
				RMResource *clickedResource = clickedItem;
				[item setEnabled:[self isCCBFileOrResourceDirectory:clickedResource]];
			}
		}
		else if (item.action == @selector(menuCreateKeyframesFromSelection:))
        {
			if([clickedItem isKindOfClass:[RMDirectory class]])
			{
				[item setEnabled:NO];
			}
		}
    }

    return menu;
}

- (BOOL)isSomethingSelected
{
	return [[self selectedRowIndexes] count] > 0;
}

- (BOOL)isCCBFileOrResourceDirectory:(RMResource *)clickedResource
{
	return clickedResource.type == kCCBResTypeCCBFile || clickedResource.type == kCCBResTypeDirectory;
}

- (void)deleteResources:(NSIndexSet *)resources
{
	NSUInteger row = [resources firstIndex];

	NSMutableArray *resourcesToDelete = [[NSMutableArray alloc] init];
	NSMutableArray *foldersToDelete = [[NSMutableArray alloc] init];

	while (row != NSNotFound)
	{
		id selectedItem = [self itemAtRow:row];
		if ([selectedItem isKindOfClass:[RMResource class]])
		{
			RMResource *resource = (RMResource *) selectedItem;
			if (resource.type == kCCBResTypeDirectory)
			{
				[foldersToDelete addObject:resource];
			}
			else
			{
				[resourcesToDelete addObject:resource];
			}
		}

		row = [resources indexGreaterThanIndex:row];
	}

	for (RMResource *res in resourcesToDelete)
	{
		[ResourceManager removeResource:res];
	}

	for (RMResource *res in foldersToDelete)
	{
		[ResourceManager removeResource:res];
	}

	[self deselectAll:NULL];

	[[ResourceManager sharedManager] reloadAllResources];
}

- (void)deleteSelectedResourcesWithRightClickedRow:(NSInteger)rightClickedRowIndex
{
    if([self selectedRow] == -1 && rightClickedRowIndex == -1)
    {
        NSBeep();
        return;
    }
    
 
	NSIndexSet *selectedRows;
	if ([self isRightClickInSelectionOrEmpty:rightClickedRowIndex])
	{
		selectedRows = [self selectedRowIndexes];
	}
	else
	{
		selectedRows = [NSIndexSet indexSetWithIndex:(NSUInteger)rightClickedRowIndex];
	}

	NSUInteger row = [selectedRows firstIndex];
	id selectedItem = [self itemAtRow:row];
	if (![selectedItem isKindOfClass:[RMResource class]])
	{
		return;
	}

	// Confirm remove of items
    NSAlert* alert = [NSAlert alertWithMessageText:@"Are you sure you want to delete the selected files?"
									 defaultButton:@"Cancel"
								   alternateButton:@"Delete"
									   otherButton:NULL
						 informativeTextWithFormat:@"You cannot undo this operation."];
	
    NSInteger result = [alert runModal];
	if (result == NSAlertDefaultReturn)
    {
        return;
    }
	
	[self deleteResources:selectedRows];
}

- (BOOL)isRightClickInSelectionOrEmpty:(NSInteger)rightClickedRowIndex
{
	return ([self isSomethingSelected] && [[self selectedRowIndexes] containsIndex:(NSUInteger)rightClickedRowIndex])
		   || rightClickedRowIndex < 0;
}

- (void) keyDown:(NSEvent *)theEvent
{
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if(key == NSDeleteCharacter)
    {
		[self deleteSelectedResourcesWithRightClickedRow:-1];
        return;
    }
    
    [super keyDown:theEvent];
}

@end
