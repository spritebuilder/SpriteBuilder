//
//  SBTextView.m
//  SpriteBuilder
//
//  Created by Martin Walsh on 29/10/2014.
//
//

#import "InspectorTextView.h"

@implementation InspectorTextView

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (!self) return NULL;

    [self setup];

    return self;
}

- (void) setup {
    // Disable ALL Smart Settings
    self.textContainer.textView.enabledTextCheckingTypes = 0;
}

@end
