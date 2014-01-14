//
//  CCBColorView.m
//  CocosBuilder
//
//  Created by Viktor on 7/26/13.
//
//

#import "CCBColorView.h"

@implementation CCBColorView

- (void) setBackgroundColor:(NSColor *)backgroundColor
{
    if (backgroundColor != _backgroundColor)
    {
        _backgroundColor = [backgroundColor copy];
        
        [self setNeedsDisplay:YES];
    }
}

- (void) setBorderColor:(NSColor *)borderColor
{
    if (borderColor != _borderColor)
    {
        _borderColor = [borderColor copy];
        
        [self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (_backgroundColor)
    {
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:_radius yRadius:_radius];
        [_backgroundColor setFill];
        [path fill];
    }
    if (_borderColor)
    {
        NSRect inset = NSMakeRect(self.bounds.origin.x+2, self.bounds.origin.y+2, self.bounds.size.width-4, self.bounds.size.height-4);
        
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:inset xRadius:_radius-2 yRadius:_radius-2];
        [_borderColor setStroke];
        [path setLineWidth:2];
        [path stroke];
    }
    [super drawRect:dirtyRect];
}


@end
