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

#import <Foundation/Foundation.h>
#import "SCEvents.h"
#import "SCEvent.h"

@class RMResource;
@class RMDirectory;

#define kCCBMaxTrackedDirectories 50


@interface ResourceManager : NSObject <SCEventListenerProtocol>
{
    NSMutableArray* resSpriteFrames;
    NSMutableArray* resBMFonts;
    
    NSMutableDictionary* directories;
    
    NSMutableArray* activeDirectories;
    
    SCEvents* pathWatcher;
    NSMutableArray* resourceObserver;
    
    NSArray* systemFontList;
    
    BOOL tooManyDirectoriesAdded;
}

+ (ResourceManager*) sharedManager;

@property (nonatomic,readonly) NSMutableDictionary* directories;
@property (nonatomic,strong) NSArray* activeDirectories;
@property (nonatomic,readonly) NSString* mainActiveDirectoryPath;
@property (nonatomic,assign) BOOL tooManyDirectoriesAdded;

@property (nonatomic,readonly) NSArray* systemFontList;

// Will remove all active directories first then recreate all file system observers anew
- (void)setActiveDirectoriesWithFullReset:(NSArray *)activeDirectories;

- (void) addDirectory:(NSString*)dir;
- (void) removeDirectory:(NSString*)dir;
- (void) removeAllDirectories;

- (void) setActiveDirectory:(NSString *)dir;

- (void) addResourceObserver:(id)observer;
- (void) removeResourceObserver:(id)observer;

- (void) reloadAllResources;

// Will update the resource manager immediately for a new file instead of waiting for
// the pathWatcher to trigger
- (void)updateForNewFile:(NSString *)newFile;

- (NSString*) toAbsolutePath:(NSString*)path;
+ (NSArray*) resIndependentExts;
+ (NSArray*) resIndependentDirs;

- (void) createCachedImageFromAuto:(NSString*)autoFile saveAs:(NSString*)dstFile forResolution:(NSString*)res;

- (void) notifyResourceObserversResourceListUpdated;

+ (BOOL) importResources:(NSArray*) resources intoDir:(NSString*) dstDir;
+ (BOOL) moveResourceFile:(NSString*)srcFile ofType:(int) type toDirectory:(NSString*) dstDir;
+ (void) renameResourceFile:(NSString*)srcPath toNewName:(NSString*) newName;
+ (void) removeResource:(RMResource*) res;

+ (void) touchResource:(RMResource*) res;

// *** Locating resources ***
- (RMResource*) resourceForPath:(NSString*) path;
- (RMResource*) resourceForPath:(NSString*) path inDir:(RMDirectory*) dir;

- (NSString *)dirPathWithFirstDirFallbackForResource:(id)resource;
- (NSString *)dirPathForResource:(id)resource;

// *** Debug ***
- (void) debugPrintDirectories;

@end
