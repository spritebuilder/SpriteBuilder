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

- (id)initWithCommandDescription:(NSScriptCommandDescription *)commandDef
{
    return [super initWithCommandDescription:commandDef];
}

- (id)performDefaultImplementation
{
    [[AppDelegate appDelegate] publishAndRun:NO async:NO ];
    return [NSNumber numberWithBool:YES];
}

@end
