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
#import "ResourceContextMenu.h"
#import "ResourceCommandController.h"


@interface ResourceManagerOutlineView()

@property (nonatomic, strong) id mouseEventMonitor;

@end


@implementation ResourceManagerOutlineView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self)
    {
        // NW: bugfix for source list highlight style for right clicks otherwise no highlighting borders
        self.menu = [[NSMenu alloc] init];

        self.mouseEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask)
                                                                       handler:^NSEvent *(NSEvent *event)
        {
            [self abortEditingOnMouseDownOutsideOfView];
            return event;
        }];
}
    return self;
}

- (void)dealloc
{
    [NSEvent removeMonitor:_mouseEventMonitor];
}

- (void)abortEditingOnMouseDownOutsideOfView
{
    NSPoint globalLocation = [NSEvent mouseLocation];
    NSPoint windowLocation = [[self window] convertScreenToBase:globalLocation];
    NSPoint viewLocation = [self convertPoint:windowLocation fromView:nil];
    if (!NSPointInRect(viewLocation, [self bounds]))
    {
        [self abortEditing];
    }
}

- (NSMenu *)menuForEvent:(NSEvent *)evt
{
    // NW: It's called to draw a highlight on the right clicked item,
    // the menu outlet of the outline view has to be just set as well
    [super menuForEvent:evt];

    return [[ResourceContextMenu alloc] initWithActionTarget:_actionTarget resources:[self selectedResources]];
}

- (NSArray *)selectedResources
{
    NSMutableArray *result = [NSMutableArray array];
    NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];

    [selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
    {
        id object = [self itemAtRow:idx];
        if (object)
        {
            [result addObject:object];
        }
    }];

    // If right click is not within selection just return the right clicked resource
    // Otherwise move it to the beginng of returned objects
    NSInteger index = [self clickedRow];
    id clickedObject = [self itemAtRow:index];
    if (clickedObject)
    {
        if ([result containsObject:clickedObject])
        {
            NSUInteger clickedObjectIndexInResult = [result indexOfObject:clickedObject];
            [result removeObjectAtIndex:clickedObjectIndexInResult];
        }
        else
        {
            [result removeAllObjects];
        }
        [result insertObject:clickedObject atIndex:0];
    }

    return result;
}

- (void) keyDown:(NSEvent *)theEvent
{
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if((key == NSDeleteCharacter
       || key == NSDeleteFunctionKey)
       && [_actionTarget respondsToSelector:@selector(deleteResource:)])
    {
        [_actionTarget deleteResource:nil];
        return;
    }

    [super keyDown:theEvent];
}

- (void)cancelOperation:(id)sender
{
    if ([self currentEditor] != nil)
    {
        [self abortEditing];
        [[self window] makeFirstResponder:self];
    }
}

- (NSArray *)selectedResourceAndChildren
{
    NSArray *selectedResources = [self selectedResources];
    NSArray *resources = @[];

    for(id resource in selectedResources)
    {
        resources = [resources arrayByAddingObjectsFromArray:[self childrenOfResource:resource]];
    }

    return resources;
}

- (NSArray *)childrenOfResource:(id)resource
{
    NSMutableArray *result = [NSMutableArray array];

    NSInteger noOfChildren = [self.dataSource outlineView:self numberOfChildrenOfItem:resource];
    for (int i = 0; i < noOfChildren; i++)
    {
        id child = [self.dataSource outlineView:self child:i ofItem:resource];
        [result addObjectsFromArray:[self childrenOfResource:child]];
    }

    [result addObject:resource];

    return result;
}
@end