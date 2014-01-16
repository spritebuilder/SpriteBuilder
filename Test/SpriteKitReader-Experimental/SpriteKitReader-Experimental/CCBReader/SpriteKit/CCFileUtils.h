/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2008-2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 * Copyright (c) 2014 Apportable Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

// keys used for the suffix or directory dictionaries
extern NSString const *CCFileUtilsSuffixDefault;
extern NSString const *CCFileUtilsSuffixiPad;
extern NSString const *CCFileUtilsSuffixiPadHD;
extern NSString const *CCFileUtilsSuffixiPhone;
extern NSString const *CCFileUtilsSuffixiPhoneHD;
extern NSString const *CCFileUtilsSuffixiPhone5;
extern NSString const *CCFileUtilsSuffixiPhone5HD;
extern NSString const *CCFileUtilsSuffixMac;
extern NSString const *CCFileUtilsSuffixMacHD;

extern NSString const *kCCFileUtilsDefaultSearchPath;

typedef NS_ENUM(NSUInteger, CCFileUtilsSearchMode) {
	CCFileUtilsSearchModeSuffix,
	CCFileUtilsSearchModeDirectory,
};

@interface CCFileUtils : NSObject
{
	@private
	NSMutableArray* _searchResolutionsOrder;

	NSMutableDictionary *_fullPathCache;
	NSMutableDictionary* _fullPathNoResolutionsCache;
}

@property (nonatomic, readwrite, strong) NSBundle	*bundle;
@property (nonatomic, readwrite, strong) NSFileManager	*fileManager;
@property (nonatomic, readwrite, getter = isEnablediPhoneResourcesOniPad) BOOL enableiPhoneResourcesOniPad;
@property (nonatomic, copy) NSMutableDictionary *directoriesDict;
@property (nonatomic, copy) NSMutableDictionary *suffixesDict;
@property (nonatomic, copy) NSArray *searchResolutionsOrder;
@property (nonatomic, copy) NSArray *searchPath;
@property (nonatomic, readwrite) CCFileUtilsSearchMode searchMode;
@property (nonatomic, readwrite, copy) NSMutableDictionary *filenameLookup;

#ifdef __CC_PLATFORM_IOS
-(void) setiPhoneRetinaDisplaySuffix:(NSString*)iPhoneRetinaDisplaySuffix;
-(void) setiPadSuffix:(NSString*) iPadSuffix;
-(void)setiPadRetinaDisplaySuffix:(NSString*)iPadRetinaDisplaySuffix;
-(void)setiPhoneContentScaleFactor:(CGFloat)scale;
-(void)setiPadContentScaleFactor:(CGFloat)scale;
#elif defined(__CC_PLATFORM_MAC)
-(void)setMacContentScaleFactor:(CGFloat)scale;
#endif // __CC_PLATFORM_IOS

+(CCFileUtils*) sharedFileUtils;
-(void) purgeCachedEntries;
-(void) buildSearchResolutionsOrder;
-(NSString*) fullPathFromRelativePath:(NSString*) relPath;
-(NSString*) fullPathFromRelativePath:(NSString*)relPath contentScale:(CGFloat *)contentScale;
-(NSString*) fullPathFromRelativePathIgnoringResolutions:(NSString*)relPath;
-(NSString*) fullPathForFilename:(NSString*)filename;
-(NSString*) fullPathForFilenameIgnoringResolutions:(NSString*)key;
-(void) loadFilenameLookupDictionaryFromFile:(NSString*)filename;
-(NSString *)removeSuffixFromFile:(NSString*) path;
-(NSString*) standarizePath:(NSString*)path;

#ifdef __CC_PLATFORM_IOS
-(BOOL) iPhoneRetinaDisplayFileExistsAtPath:(NSString*)filename;
-(BOOL) iPadFileExistsAtPath:(NSString*)filename;
-(BOOL) iPadRetinaDisplayFileExistsAtPath:(NSString*)filename;
#endif

@end
