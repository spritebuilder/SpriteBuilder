//
//  InspectorPhysicsUnavailable.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/4/14.
//
//

#import "InspectorPhysicsUnavailable.h"
#import "AppDelegate.h"

@implementation InspectorPhysicsUnavailable
- (IBAction)onGotoFirstFrame:(id)sender {
	[[AppDelegate appDelegate] gotoAutoplaySequence];
}

@end
