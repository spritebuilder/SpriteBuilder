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

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSTableColumn *column = [tableView tableColumns][0];
    NSCell *cellPrototype = [column dataCell];
    NSFont *font = [cellPrototype font];

    CCBWarning *warning = warnings.warnings[(NSUInteger) row];

    NSDictionary *attributes = @{NSFontAttributeName:font};

    CGRect frame = [warning.description boundingRectWithSize:CGSizeMake(column.width, CGFLOAT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                  attributes:attributes];
    return frame.size.height + 8.0;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CCBWarning *warning = warnings.warnings[(NSUInteger) row];

    NSTextField *textField = cell;
    textField.stringValue = warning.description;
}

@end
