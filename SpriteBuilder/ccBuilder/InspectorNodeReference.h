//
//  InspectorNodeReference.h
//  SpriteBuilder
//
//  Created by John Twigg on 2/13/14.
//
//

#import "InspectorValue.h"
#import "CCNode+NodeInfo.h"

@interface InspectorNodeReference : InspectorValue
{
    
}

- (IBAction)handleDeleteNode:(id)sender;
- (IBAction)handleGotoNode:(id)sender;
@property CCNode * reference;
@property (readonly) NSString * nodeName;
@end
