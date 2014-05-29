//
//  InspectorAnimation.h
//  SpriteBuilder
//
//  Created by John Twigg on 5/26/14.
//
//

#import "InspectorValue.h"

@interface InspectorAnimation : InspectorValue

@property (weak) IBOutlet NSComboBoxCell *animationsComboBox;

@property NSString * animation;
@property float      tween;
@end
