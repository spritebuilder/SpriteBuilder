//
//  OutletDrawWindow.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/28/14.
//
//

#import "OutletDrawWindow.h"
#import "CCBTransparentView.h"

@interface OutletDrawView : CCBTransparentView

@end

@implementation OutletDrawView
{
    CGPoint mouseStart;
    CGPoint mouseEnd;
    
    bool    drawingEnabled;
}

-(void)startDrag:(CGPoint)startPoint
{
    mouseStart = startPoint;
    mouseEnd = startPoint;
    drawingEnabled = YES;
    [self setNeedsDisplay:YES];
    
}

-(void)updateDrag:(CGPoint)currentPoint
{
    mouseEnd = currentPoint;
    drawingEnabled = YES;
    [self setNeedsDisplay:YES];
    
}

-(void)clear
{
    drawingEnabled = NO;
    [self setNeedsDisplay:YES];
    
}

-(void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    if(drawingEnabled)
    {
        CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
        CGContextSetStrokeColorWithColor(context, [NSColor blackColor].CGColor);
        
        CGContextSetLineWidth(context, 1.0);
        
        CGContextMoveToPoint(context, mouseStart.x,mouseStart.y); //start at this point
        
        CGContextAddLineToPoint(context, mouseEnd.x, mouseEnd.y); //draw to this point
        
        // and now draw the Path!
        CGContextStrokePath(context);
    }
}

@end

@interface OutletDrawWindow()
{
    OutletDrawView * outletView;

}

@end




@implementation OutletDrawWindow
@dynamic view;

- (id)initWithContentRect:(NSRect)contentRect
{
    self  = [super initWithContentRect:contentRect];
    if(self)
    {
        [self setIgnoresMouseEvents:YES];
        
        outletView = [[OutletDrawView alloc] initWithFrame:CGRectMake(0,0,contentRect.size.width,contentRect.size.height)];
		CGColorRef color = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
        [outletView.layer setBackgroundColor:color];
		CGColorRelease(color);
		color = nil;

        [self setFrame:contentRect display:YES];
        [self setContentView:outletView];
    }
    
    return self;
}


-(void)onOutletDown:(CGPoint)startPoint
{
    
    [outletView startDrag:startPoint];
}

-(void)onOutletUp:(id)sender
{
    [outletView clear];
}

-(void)onOutletDrag:(CGPoint)currentPoint;
{
    [outletView updateDrag:currentPoint];
}


-(NSView*)view
{
    return outletView;
}

@end
