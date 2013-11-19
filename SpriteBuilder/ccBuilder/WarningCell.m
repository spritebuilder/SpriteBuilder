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
    
    NSGraphicsContext* gc = [NSGraphicsContext currentContext];
    [gc saveGraphicsState];

    NSImage * warningImage = [NSImage imageNamed:@"inspector-warning.png"];
    
    [warningImage drawInRect:CGRectMake(cellFrame.origin.x + 1,cellFrame.origin.y+1, 13, 13) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];

    NSString * warningText = self.objectValue;
    [warningText drawAtPoint:NSMakePoint(cellFrame.origin.x + warningImage.size.width +  3,cellFrame.origin.y+1) withAttributes:nil];
    
    
    [gc restoreGraphicsState];
    
}



@end
