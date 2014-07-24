//
//  ScriptingBridge.m
//  SpriteBuilder
//
//  Created by Oleg Osin on 2/27/14.
//
//

#import "SpriteBuilderCommand.h"
#import "AppDelegate.h"

enum {
	kCRelease = 'CfgR',
	kCDebug = 'CfgD',
};

@interface NSApplication (SpriteBuilderCommand)
@property (copy) NSNumber *configuration;

@end

@implementation NSApplication (SpriteBuilderCommand)

- (NSNumber*) configuration {
    switch ([AppDelegate appDelegate].projectSettings.publishEnvironment) {
		case PublishEnvironmentDevelop: return [NSNumber numberWithLong:kCDebug];
        default:
            return [NSNumber numberWithLong:kCRelease];
	}
}

- (void) setConfiguration:(NSNumber*)value {
    switch ([value longValue]) {
		case kCRelease: [AppDelegate appDelegate].projectSettings.publishEnvironment = PublishEnvironmentRelease; break;
		case kCDebug: [AppDelegate appDelegate].projectSettings.publishEnvironment = PublishEnvironmentDevelop; break;
	}
}

@end

@implementation SpriteBuilderCommand

- (id)initWithCommandDescription:(NSScriptCommandDescription *)commandDef
{
    return [super initWithCommandDescription:commandDef];
}

- (id)performDefaultImplementation
{
    [[AppDelegate appDelegate] checkForDirtyDocumentAndPublishAsync:NO];
    return [NSNumber numberWithBool:YES];
}

@end
