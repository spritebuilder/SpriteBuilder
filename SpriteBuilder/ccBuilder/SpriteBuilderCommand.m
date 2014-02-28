//
//  ScriptingBridge.m
//  SpriteBuilder
//
//  Created by Oleg Osin on 2/27/14.
//
//

#import "SpriteBuilderCommand.h"
#import "AppDelegate.h"

@implementation SpriteBuilderCommand


- (id)performDefaultImplementation {
    
    // publish

    [[AppDelegate appDelegate] publishAndRun:NO runInBrowser:NULL];
	return [NSNumber numberWithInt:1];
}

@end
