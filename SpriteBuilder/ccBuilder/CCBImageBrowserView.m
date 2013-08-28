//
//  CCBImageBrowserView.m
//  CocosBuilder
//
//  Created by Viktor on 7/25/13.
//
//

#import "CCBImageBrowserView.h"

@implementation CCBImageBrowserView

- (void) mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    [self deselectAll];
}

- (void) deselectAll
{
    [self setSelectionIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
}

@end
