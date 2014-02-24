//
//  InspectorNodeReference.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/13/14.
//
//

#import "InspectorValue.h"
#import "CCNode+NodeInfo.h"

@class InspectorNodeReference;
@interface OutletButton : NSButton

@property InspectorNodeReference * inspector;
@end

@interface InspectorNodeReference : InspectorValue
{
    
}

- (IBAction)handleDeleteNode:(id)sender;
- (IBAction)handleGotoNode:(id)sender;
- (IBAction)handleClickOutlet:(id)sender;

-(void)onOutletDown;
-(void)onOutletUp;

@property (weak) IBOutlet OutletButton *outletButton;

@property CCNode * reference;
@property (readonly) NSString * nodeName;
@end
