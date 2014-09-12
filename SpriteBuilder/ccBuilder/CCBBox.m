//
//  CCBBox.m
//  SpriteBuilder
//
//  Created by Viktor on 9/12/14.
//
//

#import "CCBBox.h"

#define CCBBOX_WHITE_COLOR 0.5

@implementation CCBBox

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    self.fillColor = [NSColor redColor];
    self.borderColor = [NSColor greenColor];
    
    return self;
}

- (void) awakeFromNib
{
    self.fillColor = [NSColor colorWithCalibratedWhite:CCBBOX_WHITE_COLOR alpha:1];
    self.borderColor = [NSColor colorWithCalibratedWhite:CCBBOX_WHITE_COLOR alpha:1];
}

- (void)drawRect:(NSRect)dirtyRect {
        
    if (self.boxType == NSBoxSeparator)
    {
        NSRect fillRect = self.bounds;
        
        if (fillRect.size.width > fillRect.size.height)
        {
            // Horizontal line
            fillRect.origin.y += (int)(fillRect.size.height/2);
            
            if (fillRect.size.height > 1) fillRect.size.height = 1;
        }
        else
        {
            // Vertical line
            fillRect.origin.x += (int)(fillRect.size.width/2);
            
            if (fillRect.size.width > 1) fillRect.size.width = 1;
        }
        
        [[NSColor colorWithCalibratedWhite:CCBBOX_WHITE_COLOR alpha:1] setFill];
        NSRectFill(fillRect);
    }
    else
    {
        [super drawRect:dirtyRect];
    }
}

@end
