//
//  InspectorNodeReference.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/13/14.
//
//

#import "InspectorNodeReference.h"
#import "PositionPropertySetter.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"
#import "MainWindow.h"

@implementation OutletDrawView
{
    CGPoint mouseStart;
    CGPoint mouseEnd;
    bool    drawingEnabled;
}

-(void)updatePoint:(CGPoint)startPoint target:(CGPoint)endPoint
{
    mouseStart = startPoint;
    mouseEnd = endPoint;
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

@implementation OutletButton
{
    bool mouseIsDown;
    bool mouseIsOver;
    
    
    NSImage* imgOutletUnSet;
    NSImage* imgOutletSet;
    
    NSTrackingRectTag trackingTag;
}

-(void)clear
{
    mouseIsDown = NO;
    mouseIsOver = NO;
}

-(void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    [super viewWillMoveToSuperview:newSuperview];
    
    CGRect myFrame= self.frame;
    myFrame.origin = CGPointZero;

    if(trackingTag)
    {
        [self removeTrackingRect:trackingTag];
        trackingTag = 0x0;
    }
    trackingTag = [self addTrackingRect:myFrame owner:self userData:nil assumeInside:NO];
    
    imgOutletSet = [NSImage imageNamed:@"joint-outlet-set.png"];
    imgOutletUnSet = [NSImage imageNamed:@"joint-outlet-unset.png"];

}

-(void)drawRect:(NSRect)dirtyRect
{
    if(self.inspector.reference)
    {
        [imgOutletSet drawInRect:dirtyRect];
        return;
    }
    
    if(mouseIsDown || mouseIsOver)
    {
        [imgOutletSet drawInRect:dirtyRect];
    }
    else
    {
        [imgOutletUnSet drawInRect:dirtyRect];
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    
    [self.inspector onOutletDown:self event:theEvent];
    mouseIsDown = YES;
    [self setNeedsDisplay:YES];
    
    NSLog(@"mouseDown finished");

}

-(void)mouseUp:(NSEvent *)theEvent
{

    mouseIsDown = NO;
    [self setNeedsDisplay:YES];
    [super mouseUp:theEvent];
    [self.inspector onOutletUp:self];

}

-(void)mouseMoved:(NSEvent *)theEvent
{
    [super mouseMoved:theEvent];
 
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    [self.inspector onOutletDrag:self event:theEvent];
}


- (void)mouseEntered:(NSEvent *)event
{
    mouseIsOver = YES;
    [self setNeedsDisplay:YES];
    [[NSCursor arrowCursor] push];
}

- (void)mouseExited:(NSEvent *)event
{
    mouseIsOver = NO;
    [self setNeedsDisplay:YES];
    [NSCursor pop];
}

@end

@implementation InspectorNodeReference
{
    CGPoint mouseDown;
    CGPoint mouseCurrent;

}

@dynamic reference;




-(void)setReference:(CCNode *)reference
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    [selection setValue:reference forKey:propertyName];
    
    [self updateAffectedProperties];
}

-(CCNode*)reference
{
    return [selection valueForKey:propertyName];
}

-(void)willBeAdded
{
    self.outletButton.inspector = self;
}


-(void)onOutletDown:(id)sender event:(NSEvent*)event
{
    if(self.reference)
        return;
    
    
    // Get the screen information.
    CGRect windowRect = [[[NSApplication sharedApplication] mainWindow] frame];
    // Capture the screen.
    {
        // Create the full-screen window if it doesn’t already  exist.
        if (!outletWindow)
        {
            // Create the full-screen window.
           
            outletWindow = [[CCBTransparentWindow alloc] initWithContentRect:windowRect];
            outletWindow.delegate = self;
            
            outletView = [[OutletDrawView alloc] initWithFrame:CGRectMake(0,0,windowRect.size.width,windowRect.size.height)];
            [outletView.layer setBackgroundColor: CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0)];

        }

              // Make the screen window the current document window.
        // Be sure to retain the previous window if you want to  use it again.
        
        [outletWindow setFrame:windowRect display:YES];
        [outletWindow setContentView:outletView];
        [[AppDelegate appDelegate].window addChildWindow:outletWindow ordered:NSWindowAbove];
        
        CGPoint centre = CGPointMake(self.outletButton.frame.size.width/2,
                                     self.outletButton.frame.size.height/2 );
        
        CGPoint worldPos = [self.outletButton convertPoint:centre toView:outletView];
        mouseDown = worldPos;
        [outletView updatePoint:mouseDown target:mouseDown];

        
        NSPasteboardItem *pbItem = [NSPasteboardItem new];
        [pbItem setDataProvider:self forTypes:[NSArray arrayWithObjects:@"com.cocosbuilder.jointBody", nil]];

        
        //create a new NSDraggingItem with our pasteboard item.
        NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
        
        
        NSDraggingSession * session = [self.outletButton beginDraggingSessionWithItems:[NSArray arrayWithObject:dragItem] event:event source:self];
        
        session.animatesToStartingPositionsOnCancelOrFail = NO;
        
         
    }
}



-(void)onOutletUp:(id)sender
{
    [outletView clear];
    [self.outletButton clear];
    [self.outletButton setNeedsDisplay:YES];
    [[AppDelegate appDelegate].window removeChildWindow:outletWindow];
    
    
}

-(void)onOutletDrag:(id)sender event:(NSEvent*)aEvent
{
    mouseCurrent = [aEvent locationInWindow];
    [outletView updatePoint:mouseDown target:mouseCurrent];
    
    
}


- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context;
{
    return NSDragOperationGeneric;
}

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint
{
    
}

- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint
{
    CGRect windowRect = [[[NSApplication sharedApplication] mainWindow] frame];
    CGPoint windowPoint = ccpSub(screenPoint, windowRect.origin);
    
    mouseCurrent = windowPoint;
    [outletView updatePoint:mouseDown target:mouseCurrent];
    
    
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    [self onOutletUp:self];
    
    NSLog(@"Node Dragging Sessioned End");
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type
{
    [pasteboard clearContents];
        
    NSDictionary * pasteData = @{@"uuid":@(selection.UUID), @"propertyName":propertyName};
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:pasteData
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0
                                                               error:NULL];
    
    [pasteboard setData:data forType:@"com.cocosbuilder.jointBody"];

}


-(IBAction)handleClickOutlet:(id)sender
{
    
    
}

-(NSString*)nodeName
{
    return self.reference.displayName;
}


- (void) refresh
{
    [self willChangeValueForKey:@"reference"];
    [self didChangeValueForKey:@"reference"];
    
    [self willChangeValueForKey:@"nodeName"];
    [self didChangeValueForKey:@"nodeName"];
    
    if(self.reference != 0)
    {
        
    }
    
}

- (IBAction)handleDeleteNode:(id)sender
{
    self.reference = nil;
}

- (IBAction)handleGotoNode:(id)sender
{
    
}


@end
