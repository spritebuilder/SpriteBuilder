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

#import "CCFileUtils.h"
#import "CCBSpriteKitCompatibility.h"
#import "CCConfiguration.h"
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

#pragma mark - CCCacheValue

@interface CCFilePath : NSObject
@property (nonatomic) NSString *fullpath;
@property (nonatomic) CGFloat contentScale;
@end

@implementation CCFilePath
-(NSString*) description
{
	return [NSString stringWithFormat:@"%@ file: '%@' contentScale: %.1f path: %@", [super description], [_fullpath lastPathComponent], _contentScale, _fullpath];
}
@end

#pragma mark CCFileUtils

@implementation CCFileUtils
{
	CGFloat _iPhoneContentScaleFactor;
	CGFloat _iPadContentScaleFactor;
	CGFloat _macContentScaleFactor;
}

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

-(id) init
{
	self = [super init];
	if (self)
	{
		_fileManager = [[NSFileManager alloc] init];
		_searchResolutionsOrder = [NSMutableArray array];
		_fullPathCache = [NSMutableDictionary dictionary];
		_fullPathNoResolutionsCache = [NSMutableDictionary dictionary];
		_filenameLookup = [NSMutableDictionary dictionary];
		
		_iPhoneContentScaleFactor = 1.0;
		_iPadContentScaleFactor = 1.0;
		_macContentScaleFactor = 1.0;
	}
	
	return self;
}

- (void) buildSearchResolutionsOrder
{
	CCDevice device = [CCConfiguration sharedConfiguration].runningDevice;
	
	[_searchResolutionsOrder removeAllObjects];
	
#ifdef __CC_PLATFORM_IOS
	if (device == CCDeviceiPadRetinaDisplay)
	{
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPadHD];
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPad];
		if( _enableiPhoneResourcesOniPad ) {
			[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhone5HD];
			[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhoneHD];
		}
	}
	else if (device == CCDeviceiPad)
	{
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPad];
		if( _enableiPhoneResourcesOniPad ) {
			[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhone5HD];
			[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhoneHD];
		}
	}
	else if (device == CCDeviceiPhone5RetinaDisplay)
	{
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhone5HD];
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhoneHD];
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhone5];
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhone];
	}
	else if (device == CCDeviceiPhoneRetinaDisplay)
	{
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhoneHD];
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhone];
	}
	else if (device == CCDeviceiPhone5)
	{
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhone5];
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhone];
	}
	else if (device == CCDeviceiPhone)
	{
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixiPhone];
	}
	
#elif defined(__CC_PLATFORM_MAC)
	if (device == CCDeviceMacRetinaDisplay)
	{
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixMacHD];
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixMac];
	}
	else if (device == CCDeviceMac)
	{
		[_searchResolutionsOrder addObject:CCFileUtilsSuffixMac];
	}
#endif
	
	[_searchResolutionsOrder addObject:CCFileUtilsSuffixDefault];
}

-(void) loadFilenameLookupDictionaryFromFile:(NSString*)filename
{
	NSString *fullpath = [self fullPathForFilenameIgnoringResolutions:filename];
	if (fullpath)
	{
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fullpath];
		NSDictionary *metadata = [dict objectForKey:@"metadata"];
		NSInteger version = [[metadata objectForKey:@"version"] integerValue];
		NSAssert2(version == 1, @"CCFileUtils ERROR: Invalid filename lookup dictionary version: %ld. Filename: %@", (long)version, filename);
		
		NSMutableDictionary *filenames = [dict objectForKey:@"filenames"];
		self.filenameLookup = filenames;
	}
}

-(NSString*) fullPathForFilenameIgnoringResolutions:(NSString*)filename
{
	// fullpath? return it
	if ([filename isAbsolutePath])
	{
		return filename;
	}
	
	// Already cached ?
	NSString* fullPath = [_fullPathNoResolutionsCache objectForKey:filename];
	if (fullPath == nil)
	{
		// Lookup rules
		NSString *newfilename = [_filenameLookup objectForKey:filename];
		if (newfilename == nil)
		{
			newfilename = filename;
		}
		
		for (NSString *path in _searchPath)
		{
			fullPath = [path stringByAppendingPathComponent:newfilename];
			
			if ([_fileManager fileExistsAtPath:fullPath])
				break;
			
			NSString *file = [fullPath lastPathComponent];
			NSString *filePath = [fullPath stringByDeletingLastPathComponent];
			
			// Default to normal resource directory
			fullPath = [_bundle pathForResource:file ofType:nil inDirectory:filePath];
			
			if (fullPath)
				break;
		}
		
		NSAssert1(fullPath && fullPath.length != 0, @"CCFileUtils: file not found: %@", filename);
		if (fullPath)
		{
			[_fullPathNoResolutionsCache setObject:fullPath forKey:filename];
		}
	}

	return fullPath;
}

/* initial dummy loader
-(NSString*) fullPathForFilename:(NSString*)filename
{
	NSString* file = [filename stringByDeletingPathExtension];
	NSString* extension = [filename pathExtension];
	NSString* path = [[NSBundle mainBundle] pathForResource:file ofType:extension inDirectory:@"Published-iOS"];
	//NSLog(@"CCFileUtils fullPathForFilename:'%@' returns '%@'", filename, path);
	return path;
}
*/

-(NSString*) fullPathForFilename:(NSString*)filename
{
	CCFilePath* filePath = [self filePathForFilename:filename contentScale:0.0];
	return filePath.fullpath;
}

-(CCFilePath*) filePathForFilename:(NSString*)filename contentScale:(CGFloat)contentScale
{
	// Already Cached ?
	CCFilePath *filePath = [_fullPathCache objectForKey:filename];
	if (filePath)
	{
		return filePath;
	}

	if (contentScale == 0.0)
	{
		contentScale = 1.0;
	}

	// in Lookup Filename dictionary ?
	NSString *newfilename = [_filenameLookup objectForKey:filename];
	if (newfilename == nil)
	{
		newfilename = filename;
	}
	
	NSString *fullPath = nil;
	filePath = [[CCFilePath alloc] init];
	
	for (NSString *path in _searchPath)
	{
		// Search with Suffixes
		for (NSString *device in _searchResolutionsOrder)
		{
			NSString *fileWithPath = [path stringByAppendingPathComponent:newfilename];
			
			if (_searchMode == CCFileUtilsSearchModeSuffix)
			{
				// Search using suffixes
				NSString *suffix = [_suffixesDict objectForKey:device];
				fullPath = [self pathForFilename:fileWithPath withSuffix:suffix];
				
				if (fullPath)
				{
					contentScale = [self contentScaleForKey:suffix inDictionary:_suffixesDict];
					break;
				}
			}
			else
			{
				// Search in subdirectories
				NSString *directory = [_directoriesDict objectForKey:device];
				fullPath = [self pathForFilename:newfilename withResourceDirectory:directory withSearchPath:path];
				
				if (fullPath)
				{
					contentScale = [self contentScaleForKey:directory inDictionary:_directoriesDict];
					break;
				}
			}
		}
		
		// there are 2 loops
		if (fullPath)
			break;
	}
	
	NSAssert1(fullPath, @"CCFileUtils: Warning: File not found: %@", filename);
	
	if (fullPath)
	{
		filePath.fullpath = fullPath;
		filePath.contentScale = contentScale;
		[_fullPathCache setObject:filePath forKey:filename];
		//NSLog(@"CCFileUtils cached: %@", filePath);
	}
	
	return filePath;
}

-(NSString*) pathForFilename:(NSString*)path withSuffix:(NSString*)suffix
{
	NSString *newName = path;
	
	// only recreate filename if suffix is valid
	if (suffix && [suffix length] > 0)
	{
		NSString *pathWithoutExtension = [path stringByDeletingPathExtension];
		NSString *name = [pathWithoutExtension lastPathComponent];
		
		// check if path already has the suffix.
		if ([name rangeOfString:suffix].location == NSNotFound)
		{
			NSString *extension = [path pathExtension];
			
			/* no ccz/gz support for Sprite Kit (yet)
			if ([extension isEqualToString:@"ccz"] || [extension isEqualToString:@"gz"])
			{
				// All ccz / gz files should be in the format filename.xxx.ccz
				// so we need to pull off the .xxx part of the extension as well
				extension = [NSString stringWithFormat:@"%@.%@", [pathWithoutExtension pathExtension], extension];
				pathWithoutExtension = [pathWithoutExtension stringByDeletingPathExtension];
			}
			*/
			
			newName = [pathWithoutExtension stringByAppendingString:suffix];
			newName = [newName stringByAppendingPathExtension:extension];
		}
		else
		{
			NSLog(@"CCFileUtils: WARNING Filename(%@) already has the suffix %@ - this exact file will be loaded regardless of the current device.", name, suffix);
		}
	}
	
	NSString *fullPath = nil;
	// only if it is not an absolute path
	if ([path isAbsolutePath] == NO)
	{
		// pathForResource also searches in .lproj directories. issue #1230
		// If the file does not exist it will return nil.
		NSString *filename = [newName lastPathComponent];
		NSString *imageDirectory = [path stringByDeletingLastPathComponent];
		
		// on iOS it is OK to pass inDirector=nil and pass a path in "Resources",
		// but on OS X it doesn't work.
		fullPath = [self pathForResource:filename ofType:nil inDirectory:imageDirectory];
	}
	else if ([_fileManager fileExistsAtPath:newName])
	{
		fullPath = newName;
	}
	
	return fullPath;
}

-(NSString*) pathForFilename:(NSString*)filename withResourceDirectory:(NSString*)resourceDirectory withSearchPath:(NSString*)searchPath
{
	NSString *fullPath = nil;
	NSString *file = [filename lastPathComponent];
	NSString *filePath = [filename stringByDeletingLastPathComponent];
	
	// searchPath + file_path + resourceDirectory
	NSString * path = [searchPath stringByAppendingPathComponent:filePath];
	path = [path stringByAppendingPathComponent:resourceDirectory];
	
	// only if it is not an absolute path
	if ([filename isAbsolutePath] == NO)
	{
		// pathForResource also searches in .lproj directories. issue #1230
		// If the file does not exist it will return nil.
		// on iOS it is OK to pass inDirector=nil and pass a path in "Resources",
		// but on OS X it doesn't work.
		fullPath = [self pathForResource:file ofType:nil inDirectory:path];
	}
	else
	{
		NSString *newName = [[filePath stringByAppendingPathComponent:path] stringByAppendingPathComponent:file];
		if ([_fileManager fileExistsAtPath:newName])
		{
			fullPath = newName;
		}
	}
	
	return fullPath;
}

-(CGFloat) contentScaleForKey:(NSString*)k inDictionary:(NSDictionary *)dictionary
{
	// XXX XXX Super Slow
	for (NSString *key in dictionary)
	{
		NSString *value = [dictionary objectForKey:key];
		if ([value isEqualToString:k])
		{
#ifdef __CC_PLATFORM_IOS
			// XXX Add this in a Dictionary
			if( [key isEqualToString:CCFileUtilsSuffixiPad] )
				return 1.0*_iPadContentScaleFactor;
			if( [key isEqualToString:CCFileUtilsSuffixiPadHD] )
				return 2.0*_iPadContentScaleFactor;
			if( [key isEqualToString:CCFileUtilsSuffixiPhone] )
				return 1.0*_iPhoneContentScaleFactor;
			if( [key isEqualToString:CCFileUtilsSuffixiPhoneHD] )
				return 2.0*_iPhoneContentScaleFactor;
			if( [key isEqualToString:CCFileUtilsSuffixiPhone5] )
				return 1.0*_iPhoneContentScaleFactor;
			if( [key isEqualToString:CCFileUtilsSuffixiPhone5HD] )
				return 2.0*_iPhoneContentScaleFactor;
			if( [key isEqualToString:CCFileUtilsSuffixDefault] )
				return 1.0;
#elif defined(__CC_PLATFORM_MAC)
			if( [key isEqualToString:CCFileUtilsSuffixMac] )
				return 1.0*_macContentScaleFactor;
			if( [key isEqualToString:CCFileUtilsSuffixMacHD] )
				return 2.0*_macContentScaleFactor;
			if( [key isEqualToString:CCFileUtilsSuffixDefault] )
				return 1.0;
#endif // __CC_PLATFORM_MAC
		}
	}
	
	NSAssert(NO, @"CCFileUtils: contentScaleForKey encountered unsupported key %@", k);
	
	return 1.0;
}

-(NSString*) pathForResource:(NSString*)resource ofType:(NSString *)ext inDirectory:(NSString *)subpath
{
    // An absolute path could be used if the searchPath contains absolute paths
    if ([subpath isAbsolutePath])
	{
        NSString *fullpath = [subpath stringByAppendingPathComponent:resource];
        if (ext)
		{
            fullpath = [fullpath stringByAppendingPathExtension:ext];
		}
        
        if ([_fileManager fileExistsAtPath:fullpath])
		{
            return fullpath;
		}
		
        return nil;
    }
    
	// Default to normal resource directory
	return [_bundle pathForResource:resource ofType:ext inDirectory:subpath];
}

#pragma mark Stubs (not implemented)

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
-(NSString*) fullPathForFilename:(NSString*)filename contentScale:(CGFloat *)contentScale
{
	NOTIMPLEMENTED();
	return nil;
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
