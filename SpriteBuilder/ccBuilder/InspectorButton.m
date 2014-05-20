//
//  InspectorButton.m
//  SpriteBuilder
//
//  Created by John Twigg on 5/20/14.
//
//

#import "InspectorButton.h"

@implementation InspectorButton

- (IBAction)onClick:(id)sender {
    SEL selector = NSSelectorFromString(self->propertyName);
    
    ((void (*)(id, SEL))[self->selection methodForSelector:selector])(self->selection, selector);
    
}

-(void)willBeAdded
{
    [super willBeAdded];
    [_button sizeToFit];
}
@end
