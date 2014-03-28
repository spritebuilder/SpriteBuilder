//
//  WarningOutlineHandler.m
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-13.
//
//

#import "WarningTableViewHandler.h"
#import "CCBWarnings.h"

@implementation WarningTableViewHandler

-(void)updateWithWarnings:(CCBWarnings *)someWarnings
{
    warnings = someWarnings;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return warnings.warnings.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CCBWarning * warning = warnings.warnings[(NSUInteger) row];
    return warning.description;
}

float heightForStringDrawing(NSString *myString, NSFont *myFont, float myWidth)
{
    NSTextStorage *textStorage = [[NSTextStorage alloc]
                                   initWithString:myString];
    NSTextContainer *textContainer = [[NSTextContainer alloc]
                                       initWithContainerSize: NSMakeSize(myWidth, FLT_MAX)] ;
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];

    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    [textStorage addAttribute:NSFontAttributeName value:myFont
                        range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:4.0];
    
    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    return (float) [layoutManager usedRectForTextContainer:textContainer].size.height;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    CCBWarning * warning = warnings.warnings[(NSUInteger) row];

    NSFont * font = [NSFont systemFontOfSize:13.0f];
    
    float height  = heightForStringDrawing(warning.description, font,
                                 249.0f);
    
    return height + 8;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CCBWarning *warning = warnings.warnings[(NSUInteger) row];

    NSTextField *textField = cell;
    textField.stringValue = warning.description;
}

@end
