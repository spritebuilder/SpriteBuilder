//
//  WarningCellController.m
//  SpriteBuilder
//
//  Created by John Twigg on 2013-11-15.
//
//

#import "WarningCell.h"
@implementation WarningCell

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    
    [super drawWithFrame:cellFrame inView:controlView];
    
    NSGraphicsContext* gc = [NSGraphicsContext currentContext];
    [gc saveGraphicsState];

    NSImage * warningImage = [NSImage imageNamed:@"editor-warning.png"];
    [warningImage drawInRect:CGRectMake(cellFrame.origin.x - 15,cellFrame.origin.y+1, 13, 13) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];

    [gc restoreGraphicsState];

    
}



-(CGRect)expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView *)view
{
    NSString * warningText = self.objectValue;
    CGSize size = [warningText sizeWithAttributes:nil];
    cellFrame.size.width = size.width;
    return cellFrame;
}

-(void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view
{
    NSString * warningText = self.objectValue;
    [warningText drawAtPoint:NSMakePoint(cellFrame.origin.x,cellFrame.origin.y) withAttributes:nil];
    
}



@end
