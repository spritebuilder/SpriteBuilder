//
//  SMTabBarButtonCell.m
//  InspectorTabBar
//
//  Created by Stephan Michels on 04.02.12.
//  Copyright (c) 2012 Stephan Michels Softwareentwicklung und Beratung. All rights reserved.
//

#import "SMTabBarButtonCell.h"

@implementation SMTabBarButtonCell

- (id)init {
    self = [super init];
    if (self) {
        self.bezelStyle = NSTexturedRoundedBezelStyle;
    }
    return self;
}

// prevent automatic state changes
- (NSInteger)nextState {
    return self.state;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    
    // Draw background only if the button is selected
    if (self.state == NSOnState) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        
        // light vertical gradient
        static NSGradient *gradient = nil;
        if (!gradient) {
            NSColor *color1 = [NSColor colorWithCalibratedWhite:0.7 alpha:0.0];
            NSColor *color2 = [NSColor colorWithCalibratedWhite:0.7 alpha:5.0];
            CGFloat loactions[] = {0.0f, 0.5f, 1.0f};
            gradient = [[NSGradient alloc] initWithColors:@[color1, color2, color1] atLocations:loactions colorSpace:[NSColorSpace genericGrayColorSpace]];
        }
        [gradient drawInRect:frame angle:-90.0f];
        
        
        // shadow on the left border
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowOffset = NSMakeSize(1.0f, 0.0f);
        shadow.shadowBlurRadius = 2.0f;
        shadow.shadowColor = [NSColor darkGrayColor];
        [shadow set];
        
        // not visible color
        [[NSColor redColor] set];
        
        CGFloat radius = 50.0;
        
        NSPoint center = NSMakePoint(NSMinX(frame) - radius, NSMidY(frame));
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:center];
        [path appendBezierPathWithArcWithCenter:center
                                         radius:radius
                                     startAngle:-90.0f 
                                       endAngle:90.0f];
        [path closePath];
        [path fill];
        
        // shadow of the right border
        shadow.shadowOffset = NSMakeSize(-1.0f, 0.0f);
        [shadow set];
        
        center = NSMakePoint(NSMaxX(frame) + radius, NSMidY(frame));
        path = [NSBezierPath bezierPath];
        [path moveToPoint:center];
        [path appendBezierPathWithArcWithCenter:center
                                         radius:radius
                                     startAngle:90.0f 
                                       endAngle:270.0f];
        [path closePath];
        [path fill];
        
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
}

@end
