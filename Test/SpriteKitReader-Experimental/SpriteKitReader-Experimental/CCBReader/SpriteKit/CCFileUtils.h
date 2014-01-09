//
//  CCFileUtils.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

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
-(NSString*) fullPathForFilename:(NSString*)filename contentScale:(CGFloat *)contentScale;
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
