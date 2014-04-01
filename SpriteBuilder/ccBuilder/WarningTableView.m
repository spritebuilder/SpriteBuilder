//
//  WarningOutlineView.m
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-12.
//
//

#import "WarningTableView.h"

@implementation WarningTableView

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint pointInWindow = [theEvent locationInWindow];
    NSPoint pointInTableView = [self convertPoint:pointInWindow toView:nil];

    int rowIndex = [self rowAtPoint:pointInTableView];

    if ([theEvent clickCount] == 1 && rowIndex == -1)
    {
        [self deselectAll:nil];
    }
    else
    {
        [super mouseDown:theEvent];
    }
}

@end
