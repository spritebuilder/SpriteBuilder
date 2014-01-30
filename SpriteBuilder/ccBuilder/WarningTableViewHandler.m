//
//  WarningOutlineHandler.m
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-13.
//
//

#import "WarningTableViewHandler.h"
#import "CCBWarnings.h"
#import "WarningCell.h"

@implementation WarningTableViewHandler

-(void)updateWithWarnings:(CCBWarnings *)_ccbWarnings
{
    ccbWarnings = nil;
    
    ccbWarnings = _ccbWarnings;
    
}

-(void)dealloc
{
    
    ccbWarnings = nil;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return ccbWarnings.warnings.count;
    
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CCBWarning * warning = ccbWarnings.warnings[row];
    return warning.description;
    
}


/*
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    return ccbWarnings.warnings[index];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [(CCBWarning*)item description];
}
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return YES;
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(WarningCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    cell.title = [NSString stringWithFormat:@"  %@",((CCBWarning*)item).description];
}*/

float heightForStringDrawing(NSString *myString, NSFont *myFont,
                             float myWidth)
{
    
    NSTextStorage *textStorage = [[NSTextStorage alloc]
                                   initWithString:myString];
    NSTextContainer *textContainer = [[NSTextContainer alloc]
                                       initWithContainerSize: NSMakeSize(myWidth, FLT_MAX)] ;
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init]
                                      ;
    
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    [textStorage addAttribute:NSFontAttributeName value:myFont
                        range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:4.0];
    
    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager
            usedRectForTextContainer:textContainer].size.height;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    CCBWarning * warning = ccbWarnings.warnings[row];
    

    NSFont * font = [NSFont systemFontOfSize:13.0f];
    
    float height  = heightForStringDrawing(warning.description, font,
                                 249.0f);
    
    return height + 8;
}


- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CCBWarning * warning = ccbWarnings.warnings[row];

    NSTextField * textField = cell;
    textField.stringValue = warning.description;
    
    
}


@end
