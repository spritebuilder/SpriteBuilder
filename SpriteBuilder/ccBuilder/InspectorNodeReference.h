//
//  InspectorNodeReference.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/13/14.
//
//

#import "InspectorValue.h"
#import "CCNode+NodeInfo.h"
#import "CCBTransparentWindow.h"
#import "CCBTransparentView.h"



@class InspectorNodeReference;

@interface OutletButton : NSView
@property InspectorNodeReference * inspector;
@end

@interface OutletDrawView : CCBTransparentView

-(void)updatePoint:(CGPoint)startPoint target:(CGPoint)endPoint;

@end


@interface InspectorNodeReference : InspectorValue <NSWindowDelegate,NSDraggingSource,NSPasteboardItemDataProvider>
{
    // Transparent window for components on top of cocos scene
    CCBTransparentWindow* outletWindow;
    OutletDrawView  * outletView;
    
    NSTrackingRectTag trackingTag;
    NSTrackingArea * trackingArea;

}

- (IBAction)handleDeleteNode:(id)sender;
- (IBAction)handleGotoNode:(id)sender;
- (IBAction)handleClickOutlet:(id)sender;

-(void)onOutletDown:(id)sender event:(NSEvent*)event;
-(void)onOutletUp:(id)sender;
-(void)onOutletDrag:(id)sender event:(NSEvent*)aEvent;


@property (weak) IBOutlet OutletButton *outletButton;

@property CCNode * reference;
@property (readonly) NSString * nodeName;
@end
