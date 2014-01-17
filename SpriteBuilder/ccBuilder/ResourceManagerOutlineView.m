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
    NSPoint pt = [self convertPoint:[evt locationInWindow] fromView:nil];
    int row=[self rowAtPoint:pt];
    
    id clickedItem = [self itemAtRow:row];

    NSMenu* menu = [AppDelegate appDelegate].menuContextResManager;
    menu.autoenablesItems = NO;
    
    NSArray* items = [menu itemArray];
    for (NSMenuItem* item in items)
    {
        if (item.action == @selector(menuCreateSmartSpriteSheet:))
        {
            if ([clickedItem isKindOfClass:[RMResource class]]) {
                RMResource* clickedResource = clickedItem;
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
                    item.tag = row;
                }
                else
                {
                    [item setEnabled:NO];
                }
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
                        item.tag = row;
                    }
                }
            }
        }
        else if (item.action == @selector(menuActionDelete:))
        {
            item.tag = row;
            item.title = @"Delete";
            
            [item setEnabled:NO];
            if([clickedItem isKindOfClass:[RMResource class]])
            {
                RMResource* clickedResource = clickedItem;
                if(clickedResource.type == kCCBResTypeCCBFile || clickedResource.type == kCCBResTypeDirectory)
                {
                    [item setEnabled:YES];
                }
            }
            
        }
        else if (item.action == @selector(menuActionInterfaceFile:))
        {
            //default behavior.
            item.title = @"New File...";
            item.tag = row;
        }
        else if (item.action == @selector(menuActionNewFolder:))
        {
            item.title = @"New Folder";
            item.tag = row;
        }
        else if (item.action == @selector(menuOpenExternal:))
        {
            item.title = @"Open With External Editor";

            if ([clickedItem isKindOfClass:[RMResource class]]) {
                RMResource* clickedResource = clickedItem;
                if (clickedResource.type == kCCBResTypeCCBFile)
                {
                    [item setEnabled:NO];
                }
                else if (clickedResource.type == kCCBResTypeDirectory)
                {
                    [item setEnabled:YES];
                    item.title = @"Open Folder in Finder";
                }
                else
                {
                    [item setEnabled:YES];
                }
            }
            item.tag = row;
        }
    }
    
    // TODO: Update menu
    
    return menu;
}

- (void) deleteSelectedResource
{
    if([self selectedRow] == -1)
    {
        NSBeep();
        return;
    }
    
    // Confirm remove of items
    NSAlert* alert = [NSAlert alertWithMessageText:@"Are you sure you want to delete the selected files?" defaultButton:@"Cancel" alternateButton:@"Delete" otherButton:NULL informativeTextWithFormat:@"You cannot undo this operation."];
    NSInteger result = [alert runModal];
    
    if (result == NSAlertDefaultReturn)
    {
        return;
    }
    
    // Iterate through rows
    NSIndexSet* selectedRows = [self selectedRowIndexes];
    NSUInteger row = [selectedRows firstIndex];
    
    NSMutableArray * resourcesToDelete = [[NSMutableArray alloc] init];
    NSMutableArray * foldersToDelete = [[NSMutableArray alloc] init];
    
    while (row != NSNotFound)
    {
        id selectedItem = [self itemAtRow:row];
        if ([selectedItem isKindOfClass:[RMResource class]])
        {
            RMResource * resouce = (RMResource *)selectedItem;
            if(resouce.type == kCCBResTypeDirectory)
            {
                [foldersToDelete addObject:resouce];
            }
            else
            {
                [resourcesToDelete addObject:resouce];
            }
        }
        
        row = [selectedRows indexGreaterThanIndex: row];
    }

    for (RMResource * res in resourcesToDelete)
    {
        [ResourceManager removeResource:res];
    }
    
    for (RMResource * res in foldersToDelete)
    {
        [ResourceManager removeResource:res];
    }
    
    [self deselectAll:NULL];
    
    [[ResourceManager sharedManager] reloadAllResources];
}

- (void) keyDown:(NSEvent *)theEvent
{
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if(key == NSDeleteCharacter)
    {
        
        [self deleteSelectedResource];
        return;
    }
    
    [super keyDown:theEvent];
}

@end
