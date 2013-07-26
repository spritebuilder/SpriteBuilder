//
//  CCBColorView.m
//  CocosBuilder
//
//  Created by Viktor on 7/26/13.
//
//

#import "CCBColorView.h"

@implementation CCBColorView

- (void)drawRect:(NSRect)dirtyRect
{
    if (_backgroundColor)
    {
        [_backgroundColor setFill];
        
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:_radius yRadius:_radius];
        [path fill];
    }
    [super drawRect:dirtyRect];
}

- (void) dealloc
{
    self.backgroundColor = NULL;
    [super dealloc];
}

@end
