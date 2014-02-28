//
//  OutletDrawWindow.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/28/14.
//
//
#import "cocos2d.h"
#import "CCBPhysicsJoint.h"
#import "CCBTransparentWindow.h"

@interface OutletDrawWindow : CCBTransparentWindow

@property (readonly) NSView* view;

//
- (id)initWithContentRect:(NSRect)contentRect;

-(void)onOutletDown:(CGPoint)startPoint;
-(void)onOutletUp:(id)sender;
-(void)onOutletDrag:(CGPoint)currentPoint;

@end
