//
//  Cocos2dTestHelpers.m
//  SpriteBuilder
//
//  Created by John Twigg on 7/28/14.
//
//

#import <XCTest/XCTest.h>
#import "Cocos2dTestHelpers.h"
#import "PlugInManager.h"
#import "PlugInExport.h"

@implementation Cocos2dTestHelpers


+(NSData*)readCCB:(NSString*)srcFileName
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:srcFileName ofType:@"ccb"];
	NSDictionary *  doc  = [NSDictionary dictionaryWithContentsOfFile:path];
	NSAssert(doc, @"Can't find animation File %@",srcFileName);
	if(doc == nil)
		return nil;
	
	PlugInExport *plugIn = [[PlugInManager sharedManager] plugInExportForExtension:@"ccbi"];
	NSData *data = [plugIn exportDocument:doc];
	return data;
}


@end
