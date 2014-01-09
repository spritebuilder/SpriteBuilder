//
//  CCFileUtils.m
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#import "CCFileUtils.h"
#import "CCBSpriteKitMacros.h"

NSString *CCFileUtilsSuffixDefault = @"default";

NSString *CCFileUtilsSuffixiPad = @"ipad";
NSString *CCFileUtilsSuffixiPadHD = @"ipadhd";
NSString *CCFileUtilsSuffixiPhone = @"iphone";
NSString *CCFileUtilsSuffixiPhoneHD = @"iphonehd";
NSString *CCFileUtilsSuffixiPhone5 = @"iphone5";
NSString *CCFileUtilsSuffixiPhone5HD = @"iphone5hd";
NSString *CCFileUtilsSuffixMac = @"mac";
NSString *CCFileUtilsSuffixMacHD = @"machd";

NSString *kCCFileUtilsDefaultSearchPath = @"";

@implementation CCFileUtils

static CCFileUtils *fileUtils = nil;

// Private method to reset all the saved state that FileUtils holds on to. Useful for unit tests.
+(void) resetSingleton
{
	fileUtils = nil;
}

+(CCFileUtils*) sharedFileUtils
{
	if (fileUtils == nil)
	{
		fileUtils = [[self alloc] init];
	}
	return fileUtils;
}

#ifdef __CC_PLATFORM_IOS
-(void) setiPhoneRetinaDisplaySuffix:(NSString*)iPhoneRetinaDisplaySuffix
{
	NOTIMPLEMENTED();
}
-(void) setiPadSuffix:(NSString*) iPadSuffix
{
	NOTIMPLEMENTED();
}
-(void)setiPadRetinaDisplaySuffix:(NSString*)iPadRetinaDisplaySuffix
{
	NOTIMPLEMENTED();
}
-(void)setiPhoneContentScaleFactor:(CGFloat)scale
{
	NOTIMPLEMENTED();
}
-(void)setiPadContentScaleFactor:(CGFloat)scale
{
	NOTIMPLEMENTED();
}
#elif defined(__CC_PLATFORM_MAC)
-(void)setMacContentScaleFactor:(CGFloat)scale
{
	NOTIMPLEMENTED();
}
#endif // __CC_PLATFORM_IOS

-(void) purgeCachedEntries
{
	NOTIMPLEMENTED();
}
-(void) buildSearchResolutionsOrder
{
	NOTIMPLEMENTED();
}
-(NSString*) fullPathFromRelativePath:(NSString*) relPath
{
	NOTIMPLEMENTED();
	return nil;
}
-(NSString*) fullPathFromRelativePath:(NSString*)relPath contentScale:(CGFloat *)contentScale
{
	NOTIMPLEMENTED();
	return nil;
}
-(NSString*) fullPathFromRelativePathIgnoringResolutions:(NSString*)relPath
{
	NOTIMPLEMENTED();
	return nil;
}
-(NSString*) fullPathForFilename:(NSString*)filename
{
	NOTIMPLEMENTED();
	return nil;
}
-(NSString*) fullPathForFilename:(NSString*)filename contentScale:(CGFloat *)contentScale
{
	NOTIMPLEMENTED();
	return nil;
}
-(NSString*) fullPathForFilenameIgnoringResolutions:(NSString*)key
{
	NOTIMPLEMENTED();
	return nil;
}
-(void) loadFilenameLookupDictionaryFromFile:(NSString*)filename
{
	NOTIMPLEMENTED();
}
-(NSString *)removeSuffixFromFile:(NSString*) path
{
	NOTIMPLEMENTED();
	return nil;
}
-(NSString*) standarizePath:(NSString*)path
{
	NOTIMPLEMENTED();
	return nil;
}

#ifdef __CC_PLATFORM_IOS
-(BOOL) iPhoneRetinaDisplayFileExistsAtPath:(NSString*)filename
{
	NOTIMPLEMENTED();
	return NO;
}
-(BOOL) iPadFileExistsAtPath:(NSString*)filename
{
	NOTIMPLEMENTED();
	return NO;
}
-(BOOL) iPadRetinaDisplayFileExistsAtPath:(NSString*)filename
{
	NOTIMPLEMENTED();
	return NO;
}
#endif

@end
