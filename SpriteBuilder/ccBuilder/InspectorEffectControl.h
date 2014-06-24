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
@property (readonly) id<CCEffectNodeProtocol> effectNode;


@end
