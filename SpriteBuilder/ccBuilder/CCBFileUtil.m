/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
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

#import "CCBFileUtil.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"
#import "CCBDocument.h"
#import "ResolutionSetting.h"
#import "ProjectSettings.h"

@implementation CCBFileUtil

+ (NSString*) toResolutionIndependentFile:(NSString*)file
{
    AppDelegate* ad = [AppDelegate appDelegate];
    
    if (!ad.currentDocument)
    {
        #if !TESTING
        NSLog(@"No document!");
        #endif
        return file;
    }
    
    NSArray* resolutions = ad.currentDocument.resolutions;
    if (!resolutions)
    {
        NSLog(@"No resolutions!");
        return file;
    }
    
    NSString* fileType = [file pathExtension];
    NSString* fileNoExt = [file stringByDeletingPathExtension];
    
    ResolutionSetting* res = [resolutions objectAtIndex:ad.currentDocument.currentResolution];
    
    for (NSString* ext in res.exts)
    {
        if ([ext isEqualToString:@""]) continue;
        
        if ([fileType isEqualToString:@"bmfont"])
        {
            // Bitmap fonts are special directories, return the actual .fnt file
            NSString* fileName = [fileNoExt lastPathComponent];
            NSString* resFile = [NSString stringWithFormat:@"%@/resources-%@/%@.fnt", file,ext, fileName];
            
            NSLog(@"proposed fnt file: %@", resFile);
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            {
                return resFile;
            }
        }
        else
        {
            NSString* resFile = [NSString stringWithFormat:@"%@-%@.%@",fileNoExt,ext,fileType];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            {
                return resFile;
            }
        }
    }
    return file;
}

+ (void) addFilesWithExtension:(NSString*)ext inDirectory:(NSString*)dir toArray:(NSMutableArray*)array subPath:(NSString*)subPath
{
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:NULL];
    for (NSString* file in files)
    {
        if ([[file pathExtension] isEqualToString:ext])
        {
            if ([subPath isEqualToString:@""])
            {
                [array addObject:file];
            }
            else
            {
                [array addObject:[subPath stringByAppendingPathComponent:file]];
            }
        }
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[dir stringByAppendingPathComponent:file] isDirectory:&isDirectory];
        if (isDirectory)
        {
            NSString* childDir = [dir stringByAppendingPathComponent:file];
            NSString* childSubPath = [subPath stringByAppendingPathComponent:file];
            if ([subPath isEqualToString:@""]) childSubPath = file;
            
            [self addFilesWithExtension:ext inDirectory:childDir toArray:array subPath:childSubPath];
        }
    }
}

+ (NSArray*) filesInResourcePathsWithExtension:(NSString*)ext
{
    ProjectSettings* projectSettings = [AppDelegate appDelegate].projectSettings;
    NSMutableArray* files = [NSMutableArray array];
    
    for (NSString* dir in projectSettings.absolutePackagePaths)
    {
        [self addFilesWithExtension:ext inDirectory:dir toArray:files subPath:@""];
    }
    
    return files;
}

+ (NSDate*) modificationDateForFile:(NSString*)file
{
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:NULL];
    return [attr objectForKey:NSFileModificationDate];
}

+ (void) setModificationDate:(NSDate*)date forFile:(NSString*)file
{
    NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
                                   date, NSFileModificationDate, NULL];
    [[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:file error:NULL];
}

+(void) cleanupSpriteBuilderProjectAtPath:(NSString*)path
{
	// The files/folders in this list will be DELETED from the project at the given path.
	// This list needs to be updated/amended whenever cocos2d introduces new or renames folders whose contents are
	// not needed during development of a SpriteBuilder project. See: https://github.com/spritebuilder/SpriteBuilder/issues/915
	NSArray* removeItems = @[@"build",
							 @"cocos2d-tests-android",
							 @"cocos2d-tests-ios.xcodeproj",
							 @"cocos2d-tests-android",
							 @"cocos2d-tests-osx.xcodeproj",
							 @"cocos2d-tests.xcodeproj",
							 @"cocos2d-ui-tests",
							 @"Resources",
							 @"Resources-iPad",
							 @"Resources-Mac",
							 @"tools",
							 @"tests",
							 @"UnitTests",
							 @"doxygen.config",
							 @"doxygen.footer",
							 @"Default-568h@2x.png",
							 @"Icon.png",
							 @"RELEASE TODO.txt",
							 @"external/Chipmunk/Demo",
							 @"external/Chipmunk/doc",
							 @"external/Chipmunk/doc-src",
							 @"external/Chipmunk/msvc",
							 @"external/Chipmunk/xcode",
							 @"external/ObjectAL/ObjectAL/diagrams",
							 @"external/ObjectAL/ObjectALDemo",
							 @"external/ObjectAL/Sample Code",
							 @"external/ObjectAL/ObjectAL.pdf",
							 @"external/ObjectAL/external/ogg/doc",
							 @"external/ObjectAL/external/ogg/win32",
							 @"external/ObjectAL/external/tremor/doc",
							 @"external/ObjectAL/external/tremor/win32",
							 @"external/SSZipArchive/Example",
							 @"external/SSZipArchive/Tests",
							 ];
	
	// removing extranous cocos2d-iphone files if existing
	const NSString* const cocosPath = @"Source/libs/cocos2d-iphone";
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* parentPath = [path stringByDeletingLastPathComponent];
	NSError* error;

	// just to be sure we don't accidentally remove something when given an incorrect .ccbproj path
	if ([parentPath hasSuffix:@".spritebuilder"])
	{
		for (NSString* removeItem in removeItems)
		{
			NSString* removePath = [NSString pathWithComponents:@[parentPath, cocosPath, removeItem]];
			
			if ([fm fileExistsAtPath:removePath])
			{
				[fm removeItemAtPath:removePath error:&error];
				if (error)
				{
					NSLog(@"WARNING: cleanup failed to remove path at %@ - reason: %@", removePath, error);
				}
			}
			else
			{
				//NSLog(@"Developer Warning: tried to cleanup non-existent path: %@", removePath);
			}
		}
	}
	else
	{
		NSAssert1(nil, @"Tried to cleanup .ccbproj path whose parent folder doesn't have the .spritebuilder extension: %@", path);
	}
}

@end
