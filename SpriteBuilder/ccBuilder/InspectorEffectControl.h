//
//  InspectorEffectControl.h
//  SpriteBuilder
//
//  Created by John Twigg on 6/23/14.
//
//

#import "InspectorValue.h"
#import "CCBPEffectNode.h"

@interface InspectorEffectControl : InspectorValue <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSButton *addEffectButton;
@property (nonatomic, weak) IBOutlet NSButton *removeEffectButton;

@property (readonly) id<CCEffectNodeProtocol> effectNode;

@end
