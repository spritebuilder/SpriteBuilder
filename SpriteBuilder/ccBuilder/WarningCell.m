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
    CGContextRef context = [gc graphicsPort];
    

    
    [gc saveGraphicsState];

    
    CGPoint  points[2];
    points[0].x = 0;
    points[0].y = cellFrame.origin.y + cellFrame.size.height + 1;
    points[1].x = 249;
    points[1].y = cellFrame.origin.y + cellFrame.size.height + 1;
    
    
    CGContextSetStrokeColorWithColor(context, [NSColor grayColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    CGMutablePathRef mutablePath = CGPathCreateMutable();
    CGPathAddLines(mutablePath, nil, points, 2);
    
    CGPathCloseSubpath(mutablePath);
    
    CGContextBeginPath(context);
    CGContextAddPath(context, mutablePath);
    CGContextClosePath( context ); //ensure path is closed, not necessary if you know it is
    CGPathDrawingMode mode = kCGPathStroke;
    CGContextDrawPath( context, mode );
    
    CFRelease(mutablePath);

    
    
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
