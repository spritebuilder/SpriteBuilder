//
//  WarningOutlineHandler.m
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-13.
//
//

#import "WarningOutlineHandler.h"
#import "CCBWarnings.h"

@implementation WarningOutlineHandler

-(void)updateWithWarnings:(CCBWarnings *)_ccbWarnings
{
    [ccbWarnings release];
    ccbWarnings = nil;
    
    ccbWarnings = _ccbWarnings;
    [ccbWarnings retain];
    
}

-(void)dealloc
{
    [super dealloc];
    
    [ccbWarnings release];
    ccbWarnings = nil;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item ==  nil)
    {
        return ccbWarnings.warnings.count;
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    return ccbWarnings.warnings[index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}

/* NOTE: this method is optional for the View Based OutlineView.
 */
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [(CCBWarning*)item description];
}



@end
