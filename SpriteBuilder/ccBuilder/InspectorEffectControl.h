//
//  InspectorEffectControl.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "InspectorValue.h"
#import "CCBPEffectNode.h"
#import "NSKeyboardForwardingView.h"

@interface InspectorEffectControl : InspectorValue <NSTableViewDataSource, NSTableViewDelegate, KeyboardEventHandler>

@property (nonatomic, weak) IBOutlet NSButton *addEffectButton;
@property (nonatomic, weak) IBOutlet NSButton *removeEffectButton;

@property (readonly) id<CCEffectNodeProtocol> effectNode;

@end
