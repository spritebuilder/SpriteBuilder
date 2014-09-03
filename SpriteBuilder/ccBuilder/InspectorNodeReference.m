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
#import "EffectsManager.h"
#import "CCEffect.h"

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
    
    imgOutletSet = [NSImage imageNamed:@"inspector-body-connected.png"];
    imgOutletUnSet = [NSImage imageNamed:@"inspector-body-disconnected.png"];
	self.enabled = YES;

}

-(void)drawRect:(NSRect)dirtyRect
{
	float opacity = self.enabled ? 1.0f : 0.5f;
	NSRect frame = NSMakeRect(0,0, self.frame.size.width, self.frame.size.height);
	
    if(self.inspector.reference)
    {
        [imgOutletSet drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:opacity];
        return;
    }
    else if((mouseIsDown || mouseIsOver) && self.enabled)
    {
        [imgOutletSet drawInRect:frame];
    }
    else
    {
        [imgOutletUnSet drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:opacity];
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    [self.inspector onOutletDown:self event:theEvent];
    mouseIsDown = YES;
    [self setNeedsDisplay:YES];

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
 

}

@dynamic reference;

-(void)awakeFromNib
{
	[super awakeFromNib];
	self.dragType = DragTypeJoint;
}

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
	self.outletButton.enabled = !self.readOnly;
}

-(void)setReadOnly:(BOOL)_readOnly
{
	[super setReadOnly:_readOnly];
	self.outletButton.enabled = !self.readOnly;
}

-(void)onOutletDown:(id)sender event:(NSEvent*)event
{
    if(self.reference)
        return;
	
	if(self.readOnly)
		return;
    
    
    // Get the screen information.
    CGRect windowRect = [[[NSApplication sharedApplication] mainWindow] frame];
    // Capture the screen.
    {
       
        // Make the screen window the current document window.
        outletWindow = [[OutletDrawWindow alloc] initWithContentRect:windowRect];

        [[AppDelegate appDelegate].window addChildWindow:outletWindow ordered:NSWindowAbove];
        
        CGPoint centre = CGPointMake(self.outletButton.frame.size.width/2,
                                     self.outletButton.frame.size.height/2 );
        
      
        CGPoint viewPos = [self.outletButton convertPoint:centre toView:outletWindow.view];
        [outletWindow onOutletDown:viewPos];
        
        
        NSPasteboardItem *pbItem = [NSPasteboardItem new];
		

		if(self.dragType == DragTypeJoint)
			[pbItem setDataProvider:self forTypes:[NSArray arrayWithObjects:@"com.cocosbuilder.jointBody", nil]];
		else
			[pbItem setDataProvider:self forTypes:[NSArray arrayWithObjects:@"com.cocosbuilder.effectSprite", nil]];
		

        //create a new NSDraggingItem with our pasteboard item.
        NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
        
        
        NSDraggingSession * session = [self.outletButton beginDraggingSessionWithItems:[NSArray arrayWithObject:dragItem] event:event source:self];
        
        session.animatesToStartingPositionsOnCancelOrFail = NO;
        
         
    }
}



-(void)onOutletUp:(id)sender
{
    [outletWindow onOutletUp:sender];
    [[AppDelegate appDelegate].window removeChildWindow:outletWindow];
    outletWindow = nil;
    [self.outletButton clear];
    [self.outletButton setNeedsDisplay:YES];

    
    
}

-(void)onOutletDrag:(id)sender event:(NSEvent*)aEvent
{
    
    
}


- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context;
{
    return NSDragOperationGeneric;
}


- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint
{
    CGRect windowRect = [[[NSApplication sharedApplication] mainWindow] frame];
    CGPoint windowPoint = ccpSub(screenPoint, windowRect.origin);
    
    [outletWindow onOutletDrag:windowPoint];
    
    
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    [self onOutletUp:self];
    
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type
{

    
	if(self.dragType == DragTypeJoint)
	{
		NSDictionary * pasteData = @{@"uuid":@(selection.UUID), @"bodyIndex":[propertyName isEqualToString:@"bodyA"] ? @(BodyOutletA) : @(BodyOutletB)};
		
		NSData *data = [NSPropertyListSerialization dataWithPropertyList:pasteData
																  format:NSPropertyListBinaryFormat_v1_0
																 options:0
																   error:NULL];
		
		[pasteboard setData:data forType:@"com.cocosbuilder.jointBody"];
	}
	
	if(self.dragType == DragTypeEffectSprite)
	{
		CCEffect<EffectProtocol> *effect = (CCEffect<EffectProtocol>*)selection;
		
		NSDictionary * pasteData = @{@"effect":@(effect.UUID),@"propertyName" : propertyName};
		
		NSData *data = [NSPropertyListSerialization dataWithPropertyList:pasteData
																  format:NSPropertyListBinaryFormat_v1_0
																 options:0
																   error:NULL];
		
		[pasteboard setData:data forType:@"com.cocosbuilder.effectSprite"];
	}

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
    
	[self.outletButton setNeedsDisplay:YES];
    [super refresh];    
}

- (IBAction)handleDeleteNode:(id)sender
{
    self.reference = nil;
}

- (IBAction)handleGotoNode:(id)sender
{
	if(self.reference)
		[[AppDelegate appDelegate] setSelectedNodes:@[self.reference]];
}


@end
