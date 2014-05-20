//
//  InspectorButton.h
//  SpriteBuilder
//
//  Created by John Twigg on 5/20/14.
//
//

#import "InspectorValue.h"

@interface InspectorButton : InspectorValue
- (IBAction)onClick:(id)sender;
@property (weak) IBOutlet NSButton *button;


@end
