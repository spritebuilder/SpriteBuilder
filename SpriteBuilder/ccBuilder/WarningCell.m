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

    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    CGContextRef context = [gc graphicsPort];

    [gc saveGraphicsState];

    CGContextSetLineWidth(context, 0.5);
    CGContextSetStrokeColorWithColor(context, [NSColor grayColor].CGColor);
    CGContextMoveToPoint(context, 0.0, cellFrame.origin.y + cellFrame.size.height + 0.5);
    CGContextAddLineToPoint(context, 249.0, cellFrame.origin.y + cellFrame.size.height + 0.5);
    CGContextStrokePath(context);

    [gc restoreGraphicsState];
}

@end
