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

#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "CCBSpriteSheetParser.h"
#import "CCBAnimationParser.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"
#import "CCBDocument.h"
#import "ResolutionSetting.h"
#import "ProjectSettings.h"
#import "CCBFileUtil.h"
#import <CoreGraphics/CGImage.h>
#import <QTKit/QTKit.h>
#import <MacTypes.h>
#import "CCBDirectoryPublisher.h"
#import "SoundFileImageController.h"
#import "MiscConstants.h"
#import "RMResource.h"
#import "RMDirectory.h"
#import "ResourceTypes.h"
#import "RMPackage.h"

@protocol ResourceManager_UndeclaredSelectors <NSObject>

@optional
- (void) resourceListUpdated;

@end

@implementation ResourceManager

@synthesize directories;
@synthesize activeDirectories;
@synthesize systemFontList;
@synthesize tooManyDirectoriesAdded;

#define kIgnoredExtensionsKey @"ignoredDirectoryExtensions"

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSArray arrayWithObjects:@"git", @"svn", @"xcodeproj", nil], 
      kIgnoredExtensionsKey,
      nil]];
}

- (BOOL)shouldPrunePath:(NSString *)dirPath {
    // prune directories...
    for (NSString *extension in [[NSUserDefaults standardUserDefaults] objectForKey:kIgnoredExtensionsKey]) {
        if ([dirPath hasSuffix:extension]) {
            return YES;
        }
        else if ([dirPath hasPrefix:@"."]) {
            return YES;
        }
    }
    return NO;
}

+ (ResourceManager *)sharedManager
{
	static ResourceManager *rm = NULL;
	if (!rm)
	{
		rm = [[ResourceManager alloc] init];
	}
	return rm;
}

- (void) loadFontListTTF
{
    NSMutableDictionary* fontInfo = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FontListTTF" ofType:@"plist"]];
    systemFontList = [fontInfo objectForKey:@"supportedFonts"];
}

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    directories = [[NSMutableDictionary alloc] init];
    activeDirectories = [[NSMutableArray alloc] init];
    pathWatcher = [[SCEvents alloc] init];
    pathWatcher.ignoreEventsFromSubDirs = YES;
    pathWatcher.delegate = self;
    resourceObserver = [[NSMutableArray alloc] init];
    
    [self loadFontListTTF];
    
    return self;
}

- (void) dealloc
{
    self.activeDirectories = NULL;
}

- (NSArray*) getAddedDirs
{
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:[directories count]];
    for (NSString* dirPath in directories)
    {        
        [arr addObject:dirPath];
    }
    return arr;
}



- (void) updatedWatchedPaths
{
    if (pathWatcher.isWatchingPaths)
    {
        [pathWatcher stopWatchingPaths];
    }
    [pathWatcher startWatchingPaths:[self getAddedDirs]];
}

- (void) notifyResourceObserversResourceListUpdated
{
    for (id observer in resourceObserver)
    {
        if ([observer respondsToSelector:@selector(resourceListUpdated)])
        {
            [observer performSelector:@selector(resourceListUpdated)];
        }
    }
}

+ (NSArray*) resIndependentExts
{
    return [NSArray arrayWithObjects:@"@2x",@"-phone",@"-tablet",@"-tablethd", @"-phonehd", @"-html5", @"-auto", nil];
}

+ (NSArray*) resIndependentDirs
{
    return [NSArray arrayWithObjects:@"resources-phone", @"resources-phonehd", @"resources-tablet", @"resources-tablethd", @"resources-html5", @"resources-auto", nil];
}

+ (BOOL) isResolutionDependentFile: (NSString*) file
{
    if ([[file pathExtension] isEqualToString:@"ccb"]) return NO;
    
    NSString* fileNoExt = [file stringByDeletingPathExtension];
    
    NSArray* resIndependentExts = [ResourceManager resIndependentExts];
    
    for (NSString* ext in resIndependentExts)
    {
        if ([fileNoExt hasSuffix:ext]) return YES;
    }
    
    return NO;
}

+ (int) getResourceTypeForFile:(NSString*) file
{
    NSString* ext = [[file pathExtension] lowercaseString];
    NSFileManager* fm = [NSFileManager defaultManager];
    
    BOOL isDirectory;
    [fm fileExistsAtPath:file isDirectory:&isDirectory];
    
    if (isDirectory)
    {
        // Bitmap fonts are directories, but with an extension
        if ([ext isEqualToString:@"bmfont"])
        {
            return kCCBResTypeBMFont;
        }
        
        // Hide resolution directories
        if ([[ResourceManager resIndependentDirs] containsObject:[file lastPathComponent]])
        {
            return kCCBResTypeNone;
        }
        else
        {
            return kCCBResTypeDirectory;
        }
    }
    //else if ([[file stringByDeletingPathExtension] hasSuffix:@"-hd"]
    //         || [[file stringByDeletingPathExtension] hasSuffix:@"@2x"])
    else if ([self isResolutionDependentFile:file])
    {
        // Ignore -hd files
        return kCCBResTypeNone;
    }
    else if ([ext isEqualToString:@"png"]
        || [ext isEqualToString:@"psd"]
        || [ext isEqualToString:@"jpg"]
        || [ext isEqualToString:@"jpeg"])
    {
        return kCCBResTypeImage;
    }
    else if ([ext isEqualToString:@"fnt"])
    {
        return kCCBResTypeBMFont;
    }
    else if ([ext isEqualToString:@"ttf"])
    {
        return kCCBResTypeTTF;
    }
    else if ([ext isEqualToString:@"plist"]
             && [CCBSpriteSheetParser isSpriteSheetFile:file])
    {
        return kCCBResTypeSpriteSheet;
    }
    else if ([ext isEqualToString:@"plist"]
             && [CCBAnimationParser isAnimationFile:file])
    {
        return kCCBResTypeAnimation;
    }
    else if ([ext isEqualToString:@"ccb"])
    {
        return kCCBResTypeCCBFile;
    }
    else if ([ext isEqualToString:@"js"])
    {
        return kCCBResTypeJS;
    }
    else if ([ext isEqualToString:@"json"])
    {
        return kCCBResTypeJSON;
    }
    else if ([ext isEqualToString:@"wav"]
             || [ext isEqualToString:@"mp3"]
             || [ext isEqualToString:@"m4a"]
             || [ext isEqualToString:@"caf"])
    {
        return kCCBResTypeAudio;
    }
    else if ([ext isEqualToString:@"ccbspritesheet"])
    {
        return kCCBResTypeGeneratedSpriteSheetDef;
    }
    return kCCBResTypeNone;
}

- (void) clearTouchedForResInDir:(RMDirectory*)dir
{
    NSDictionary* resources = dir.resources;
    for (NSString* file in resources)
    {
        RMResource* res = [resources objectForKey:file];
        res.touched = NO;
    }
}

- (void) updateResourcesForPath:(NSString*) path
{
    NSFileManager* fm = [NSFileManager defaultManager];
    RMDirectory* dir = [directories objectForKey:path];
    
    NSArray* resolutionDirs = [ResourceManager resIndependentDirs];
    
    // Get files from default directory
    NSMutableSet* files = [NSMutableSet setWithArray:[fm contentsOfDirectoryAtPath:path error:NULL]];
    
    for (NSString* resolutionExt in resolutionDirs)
    {
        NSString* resolutionDir = [path stringByAppendingPathComponent:resolutionExt];
        BOOL isDir = NO;
        if (![fm fileExistsAtPath:resolutionDir isDirectory:&isDir] && isDir) continue;
        
        [files addObjectsFromArray:[fm contentsOfDirectoryAtPath:resolutionDir error:NULL]];
    }
    
    NSMutableDictionary* resources = dir.resources;
    
    if (!resources)
    {
        [self updateResourcesForPath:[path stringByDeletingLastPathComponent]];
        return;
    }
    
    BOOL needsUpdate = NO; // Assets needs to be reloaded in editor
    BOOL resourcesChanged = NO;  // A resource file was modified, added or removed
    
    [self clearTouchedForResInDir:dir];
    
    for (NSString* fileShort in files)
    {
        NSString* file = [path stringByAppendingPathComponent:fileShort];
     
        if ([self shouldPrunePath:file]) continue;
        
        RMResource* res = [resources objectForKey:file];
        NSDictionary* attr = [fm attributesOfItemAtPath:file error:NULL];
        NSDate* modifiedTime = [attr fileModificationDate];
        
        if (res)
        {
            // Update generated sprite sheets
            if (res.type == kCCBResTypeDirectory)
            {
                RMDirectory* dir = res.data;
                BOOL oldValue = dir.isDynamicSpriteSheet;
                //[dir updateIsDynamicSpriteSheet];
                if (oldValue != dir.isDynamicSpriteSheet)
                {
                    resourcesChanged = YES;
                }
                [self updateResourcesForPath:res.filePath];
            }
            
            if ([res.modifiedTime compare:modifiedTime] == NSOrderedSame)
            {
                // Skip files that are not modified
                res.touched = YES;
                continue;
            }
            else if ([[AppDelegate appDelegate].currentDocument.filePath isEqualToString:file])
            {
                // Skip the current document
                res.touched = YES;
                continue;
            }
            else
            {
                // A resource has been modified, we need to reload assets
                res.modifiedTime = modifiedTime;
                res.type = [ResourceManager getResourceTypeForFile:file];
                
                // Reload its data
                [res loadData];
                
                if (res.type == kCCBResTypeSpriteSheet
                    || res.type == kCCBResTypeAnimation
                    || res.type == kCCBResTypeImage
                    || res.type == kCCBResTypeBMFont
                    || res.type == kCCBResTypeTTF
                    || res.type == kCCBResTypeCCBFile
                    || res.type == kCCBResTypeAudio
                    || res.type == kCCBResTypeGeneratedSpriteSheetDef)
                {
                    needsUpdate = YES;
                }
                resourcesChanged = YES;
                
            }
        }
        else
        {
            // This is a new resource, add it!
            res = [[RMResource alloc] init];
            res.modifiedTime = modifiedTime;
            res.type = [ResourceManager getResourceTypeForFile:file];
            res.filePath = file;
            
            // Load basic resource data if neccessary
            [res loadData];
            
            // Check if it is a directory
            if (res.type == kCCBResTypeDirectory)
            {
                [self addDirectory:file];
                res.data = [directories objectForKey:file];
            }
            
            [resources setObject:res forKey:file];
            
            if (res.type != kCCBResTypeNone) resourcesChanged = YES;
        }
        
        res.touched = YES;
    }
    
    // Check for deleted files
    NSMutableArray* removedFiles = [NSMutableArray array];
    
    for (NSString* file in resources)
    {
        RMResource* res = [resources objectForKey:file];
        if (!res.touched)
        {
            [removedFiles addObject:file];
            needsUpdate = YES;
            if (res.type != kCCBResTypeNone) resourcesChanged = YES;
        }
    }
    
    // Remove references to files marked for deletion
    for (NSString* file in removedFiles)
    {
        [resources removeObjectForKey:file];
    }
    
    // Update arrays for different resources
    if (resChanged)
    {
        [dir.any removeAllObjects];
        [dir.images removeAllObjects];
        [dir.animations removeAllObjects];
        [dir.bmFonts removeAllObjects];
        [dir.ttfFonts removeAllObjects];
        [dir.ccbFiles removeAllObjects];
        [dir.audioFiles removeAllObjects];
        
        for (NSString* file in resources)
        {
            RMResource* res = [resources objectForKey:file];
            if (res.type == kCCBResTypeImage
                || res.type == kCCBResTypeSpriteSheet
                || res.type == kCCBResTypeDirectory)
            {
                [dir.images addObject:res];
            }
            if (res.type == kCCBResTypeAnimation
                || res.type == kCCBResTypeDirectory)
            {
                [dir.animations addObject:res];
            }
            if (res.type == kCCBResTypeBMFont
                || res.type == kCCBResTypeDirectory)
            {
                [dir.bmFonts addObject:res];
            }
            if (res.type == kCCBResTypeTTF
                || res.type == kCCBResTypeDirectory)
            {
                [dir.ttfFonts addObject:res];
            }
            if (res.type == kCCBResTypeCCBFile
                || res.type == kCCBResTypeDirectory)
            {
                [dir.ccbFiles addObject:res];
                
            }
            if (res.type == kCCBResTypeAudio
                || res.type == kCCBResTypeDirectory)
            {
                [dir.audioFiles addObject:res];
                
            }
            if (res.type == kCCBResTypeImage
                || res.type == kCCBResTypeSpriteSheet
                || res.type == kCCBResTypeAnimation
                || res.type == kCCBResTypeBMFont
                || res.type == kCCBResTypeTTF
                || res.type == kCCBResTypeCCBFile
                || res.type == kCCBResTypeDirectory
                || res.type == kCCBResTypeJS
                || res.type == kCCBResTypeJSON
                || res.type == kCCBResTypeAudio)
            {
                [dir.any addObject:res];
            }
        }
        
        [dir.any sortUsingSelector:@selector(compare:)];
        [dir.images sortUsingSelector:@selector(compare:)];
        [dir.animations sortUsingSelector:@selector(compare:)];
        [dir.bmFonts sortUsingSelector:@selector(compare:)];
        [dir.ttfFonts sortUsingSelector:@selector(compare:)];
        [dir.ccbFiles sortUsingSelector:@selector(compare:)];
        [dir.audioFiles sortUsingSelector:@selector(compare:)];
    }
    
    if (resourcesChanged) [self notifyResourceObserversResourceListUpdated];
    if (needsUpdate)
    {
        [[AppDelegate appDelegate] reloadResources];
    }
}

- (void)setActiveDirectoriesWithFullReset:(NSArray *)newActiveDirectories
{
    [self removeAllDirectories];

    for (NSString* dir in newActiveDirectories)
    {
        [self addDirectory:dir];
    }

    [self setActiveDirectories:newActiveDirectories];
}

- (void) addDirectory:(NSString *)dirPath
{
    if ([directories count] > kCCBMaxTrackedDirectories)
    {
        tooManyDirectoriesAdded = YES;
        return;
    }
    
    // Check if directory is already added (then add to its count)
    RMDirectory* dir = [directories objectForKey:dirPath];
    if (dir)
    {
        dir.count++;
    }
    else
    {
        dir = [self isPackage:dirPath]
          ? [[RMPackage alloc] init]
          : [[RMDirectory alloc] init];

        dir.count = 1;
        dir.dirPath = dirPath;
        [directories setObject:dir forKey:dirPath];
        
        [self updatedWatchedPaths];
    }
    
    [self updateResourcesForPath:dirPath];
}


- (BOOL)isPackage:(NSString *)dirPath
{
    return [[dirPath lastPathComponent] hasSuffix:PACKAGE_NAME_SUFFIX];
}

- (void) removeDirectory:(NSString *)dirPath
{
    RMDirectory* dir = [directories objectForKey:dirPath];
    if (dir)
    {
        // Remove sub directories
        NSDictionary* resources = dir.resources;
        for (NSString* file in resources)
        {
            RMResource* res = [resources objectForKey:file];
            if (res.type == kCCBResTypeDirectory)
            {
                [self removeDirectory:file];
            }
        }
        
        dir.count--;
        if (!dir.count)
        {
            [directories removeObjectForKey:dirPath];
            [self updatedWatchedPaths];
        }
    }
}

- (void) removeAllDirectories
{
    [directories removeAllObjects];
    [activeDirectories removeAllObjects];
    [self updatedWatchedPaths];
    [self notifyResourceObserversResourceListUpdated];
}

- (void) setActiveDirectories:(NSArray *)ad
{
    [activeDirectories removeAllObjects];
    
    for (NSString* dirPath in ad)
    {
        RMDirectory* dir = [directories objectForKey:dirPath];
        if (dir)
        {
            [activeDirectories addObject:dir];
        }
    }
    
    [self notifyResourceObserversResourceListUpdated];
}

- (void) setActiveDirectory:(NSString *)dir
{
    [self setActiveDirectories:[NSArray arrayWithObject:dir]];
}

- (void) addResourceObserver:(id)observer
{
    [resourceObserver addObject:observer];
}

- (void) removeResourceObserver:(id)observer
{
    [resourceObserver removeObject:observer];
}

- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event
{
    [[[CCDirector sharedDirector] view] lockOpenGLContext];
    [self updateResourcesForPath:event.eventPath];
    [[[CCDirector sharedDirector] view] unlockOpenGLContext];
}

- (void) reloadAllResources
{
    [[[CCDirector sharedDirector] view] lockOpenGLContext];
    
    for (id obj in activeDirectories)
    {
        RMDirectory* dir = obj;
        NSString* dirPath = dir.dirPath;
        
        [self updateResourcesForPath:dirPath];
    }
    
    [[[CCDirector sharedDirector] view] unlockOpenGLContext];
}

- (void)updateForNewFile:(NSString *)newFile
{
    for (RMDirectory *dir in activeDirectories)
    {
        NSString *dirPath = dir.dirPath;

        if ([newFile rangeOfString:dirPath].location != NSNotFound)
        {
            [self updateResourcesForPath:dirPath];
        }
        return;
    }
}


@dynamic mainActiveDirectoryPath; // prevent auto-synthesis of property ivar of the same name
- (NSString*) mainActiveDirectoryPath
{
    if ([activeDirectories count] == 0) return NULL;
    RMDirectory* dir = [activeDirectories objectAtIndex:0];
    return dir.dirPath;
}

- (void)createCachedImageFromAuto:(NSString *)autoFile
                           saveAs:(NSString *)dstFile
                    forResolution:(NSString *)res
                  projectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"ProjectSettings must not be nil.");

    // Find settings for the file
    NSString* fileName = [autoFile lastPathComponent];
    RMResource* resource = [[RMResource alloc] init];
    resource.filePath = [[[autoFile stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];
    resource.type = [ResourceManager getResourceTypeForFile:resource.filePath];
    int tabletScale = [[projectSettings propertyForResource:resource andKey:@"tabletScale"] intValue];
    if (!tabletScale) tabletScale = 2;
    
    int srcScaleSetting = [[projectSettings propertyForResource:resource andKey:@"scaleFrom"] intValue];
    
    // Calculate the dst scale factor
    float dstScale = 1;
    if ([res isEqualToString:@"phone"])
    {
        dstScale = 1;
    }
    if ([res isEqualToString:@"phonehd"])
    {
        dstScale = 2;
    }
    else if ([res isEqualToString:@"tablet"])
    {
        dstScale = 1 * tabletScale;
    }
    else if ([res isEqualToString:@"tablethd"])
    {
        dstScale = 2 * tabletScale;
    }

    // Calculate src scale factor
    float srcScale = 1;
    if (srcScaleSetting)
    {
        // Use the manual override
        srcScale = srcScaleSetting;
    }
    else
    {
        // Use project default
        srcScale = projectSettings.resourceAutoScaleFactor;
    }
    
    // Calculate the actual factor
    float scaleFactor = dstScale/srcScale;
    
    // Load src image
	CGImageSourceRef image_source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:autoFile], NULL);
	CGImageRef imageSrc = CGImageSourceCreateImageAtIndex(image_source, 0, NULL);
	CFRelease(image_source);
	image_source = nil;
		    
    int wSrc = CGImageGetWidth(imageSrc);
    int hSrc = CGImageGetHeight(imageSrc);

    
    int wDst = wSrc * scaleFactor;
    if(wDst == 0)
        wDst = 1;
    
    int hDst = hSrc * scaleFactor;
    if(hDst == 0)
        hDst = 1;
    
    BOOL save8BitPNG = NO;
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageSrc);
    if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelIndexed)
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        save8BitPNG = YES;
    }
    
    // Create new, scaled image
    CGContextRef newContext = CGBitmapContextCreate(NULL, wDst, hDst, 8, wDst*32, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	NSAssert(newContext != nil, @"CG draw context is nil");
    
    // Enable anti-aliasing
    CGContextSetInterpolationQuality(newContext, kCGInterpolationHigh);
    CGContextSetShouldAntialias(newContext, TRUE);
    
    CGContextDrawImage(newContext, CGContextGetClipBoundingBox(newContext), imageSrc);
    
    CGImageRef imageDst = CGBitmapContextCreateImage(newContext);
    
    // Create destination directory
    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:[dstFile stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:NULL error:&error])
    {
        NSLog(@"Error creating directory \"%@\" - %@", [dstFile stringByDeletingLastPathComponent], error);
    }
    
    // Save the image
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:dstFile];
		
    // NOTE! Rescaled image is always saved as a PNG even if the output filename is .psd.
    // ImageIO discovers format types from the file header and not the extension.
    // However, later processing stages in the SB export process need the original filename to be preserved.
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, imageDst, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", dstFile);
    }
    
    // Release created objects
    CFRelease(destination);
    CGImageRelease(imageDst);
    CGImageRelease(imageSrc);
    CFRelease(newContext);
    
    // Convert file to 8 bit if original uses indexed colors
    if (save8BitPNG)
    {
        CFRelease(colorSpace);
        
        NSTask* pngTask = [[NSTask alloc] init];
        [pngTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"pngquant"]];
        NSMutableArray* args = [NSMutableArray arrayWithObjects:
                                @"--force", @"--ext", @".png", dstFile, nil];
        [pngTask setArguments:args];
        [pngTask launch];
        [pngTask waitUntilExit];
    }
    
    // Update modification time to match original file
    NSDate* autoFileDate = [CCBFileUtil modificationDateForFile:autoFile];
    [CCBFileUtil setModificationDate:autoFileDate forFile:dstFile];
}

- (NSString*) toAbsolutePath:(NSString*)path
{
    if ([activeDirectories count] == 0) return NULL;
    NSFileManager* fm = [NSFileManager defaultManager];
    AppDelegate* ad = [AppDelegate appDelegate];
    
    if (!ad.currentDocument)
    {
        // No document is currently open, grab a reference to any of the resolution files
        for (RMDirectory* dir in activeDirectories)
        {
            // First try the default
            NSString* p = [NSString stringWithFormat:@"%@/%@",dir.dirPath,path];
            if ([fm fileExistsAtPath:p]) return p;
            
            // Then try all resolution dependent directories
            NSString* fileName = [p lastPathComponent];
            NSString* dirName = [p stringByDeletingLastPathComponent];
            
            for (NSString* resDir in [ResourceManager resIndependentDirs])
            {
                NSString* p2 = [[dirName stringByAppendingPathComponent:resDir] stringByAppendingPathComponent:fileName];
                if ([fm fileExistsAtPath:p2]) return p2;
            }
        }
    }
    else
    {
        // Select by resolution definied by open document
        NSArray* resolutions = ad.currentDocument.resolutions;
        if (!resolutions) return NULL;
        
        ResolutionSetting* res = [resolutions objectAtIndex:ad.currentDocument.currentResolution];
        
        for (RMDirectory* dir in activeDirectories)
        {
            // Get the name of the default file
            NSString* defaultFile = [NSString stringWithFormat:@"%@/%@",dir.dirPath,path];
            
            NSString* defaultFileName = [defaultFile lastPathComponent];
            NSString* defaultDirName = [defaultFile stringByDeletingLastPathComponent];
            
            // Select by resolution
            for (__strong NSString* ext in res.exts)
            {
                if ([ext isEqualToString:@""]) continue;
                ext = [@"resources-" stringByAppendingString:ext];
                
                NSString* pathForRes = [[defaultDirName stringByAppendingPathComponent:ext] stringByAppendingPathComponent:defaultFileName];
                
                if ([fm fileExistsAtPath:pathForRes]) return pathForRes;
            }
            
            // Auto convert!
            NSString* autoFile = [[defaultDirName stringByAppendingPathComponent:@"resources-auto"] stringByAppendingPathComponent:defaultFileName];
            if ([fm fileExistsAtPath:autoFile])
            {
                // Check if the file exists in cache
                NSString* ext = @"";
                if ([res.exts count] > 0) ext = [res.exts objectAtIndex:0];
                
                NSString* cachedFile = [ad.projectSettings.displayCacheDirectory stringByAppendingPathComponent:path];
                if (![ext isEqualToString:@""])
                {
                    NSString* cachedFileName = [cachedFile lastPathComponent];
                    NSString* cachedDirName = [cachedFile stringByDeletingLastPathComponent];
                    cachedFile = [[cachedDirName stringByAppendingPathComponent:ext] stringByAppendingPathComponent:cachedFileName];
                }
                
                BOOL cachedFileExists = [fm fileExistsAtPath:cachedFile];
                BOOL datesMatch = NO;
                
                if (cachedFileExists)
                {
                    NSDate* autoFileDate = [CCBFileUtil modificationDateForFile:autoFile];
                    NSDate* cachedFileDate = [CCBFileUtil modificationDateForFile:cachedFile];
                    if ([autoFileDate isEqualToDate:cachedFileDate]) datesMatch = YES;
                }
                
                if (!cachedFileExists || !datesMatch)
                {
                    // Not yet cached, create file
                    [self createCachedImageFromAuto:autoFile saveAs:cachedFile forResolution:ext projectSettings:[AppDelegate appDelegate].projectSettings];
                }
                return cachedFile;
            }
            
            // Fall back on default file
            if ([fm fileExistsAtPath:defaultFile]) return defaultFile;
        }
    }
    return NULL;
}

+ (NSString*) toResolutionIndependentFile:(NSString*)file
{
    AppDelegate* ad = [AppDelegate appDelegate];
    
    if (!ad.currentDocument)
    {
        return file;
    }
    
    NSArray* resolutions = ad.currentDocument.resolutions;
    if (!resolutions)
    {
        return file;
    }
    
    NSString* fileType = [file pathExtension];
    NSString* fileNoExt = [file stringByDeletingPathExtension];
    
    ResolutionSetting* res = [resolutions objectAtIndex:ad.currentDocument.currentResolution];
    
    for (NSString* ext in res.exts)
    {
        if ([ext isEqualToString:@""]) continue;
        
        NSString* resFile = [NSString stringWithFormat:@"%@-%@.%@",fileNoExt,ext,fileType];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:resFile])
        {
            return resFile;
        }
    }
    return file;
}

#pragma mark File transformations

+ (BOOL) importFile:(NSString*) file intoDir:(NSString*) dstDir
{
    BOOL importedFile = NO;
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:file isDirectory:&isDir] && isDir)
    {
        NSString* ext = [[file pathExtension] lowercaseString];
        
        if ([ext isEqualToString:@"bmfont"])
        {
            // Handle bitmap fonts
            
            NSString* dstPath = [dstDir stringByAppendingPathComponent:[file lastPathComponent]];
            [fm copyItemAtPath:file toPath:dstPath error:NULL];
            
            importedFile = YES;
        }
        else
        {
            // Handle regular directory
            NSString* dirName = [file lastPathComponent];
            NSString* dstDirNew = [dstDir stringByAppendingPathComponent:dirName];
            
            // Create if not created
            [fm createDirectoryAtPath:dstDirNew withIntermediateDirectories:YES attributes:NULL error:NULL];
            
            NSArray* dirFiles = [fm contentsOfDirectoryAtPath:file error:NULL];
            for (NSString* fileName in dirFiles)
            {
                importedFile |= [ResourceManager importFile:[file stringByAppendingPathComponent:fileName] intoDir:dstDirNew];
            }
        }
    }
    else
    {
        // Handle regular file
        NSString* ext = [[file pathExtension] lowercaseString];
        if ([ext isEqualToString:@"png"] || [ext isEqualToString:@"psd"])
        {
            // Handle image import
            
            // Copy to resources-auto folder
            NSString* autoDir = [dstDir stringByAppendingPathComponent:@"resources-auto"];
            
            [fm createDirectoryAtPath:autoDir withIntermediateDirectories:YES attributes:NULL error:NULL];
            
            NSString* imgFileName = [autoDir stringByAppendingPathComponent:[file lastPathComponent]];
            
            [fm copyItemAtPath:file toPath:imgFileName error:NULL];
            importedFile = YES;
        }
        else if ([ext isEqualToString:@"wav"])
        {
            // Handle sound import
            
            // Code should check the wav file to see if it is longer than 15 seconds and in that case use mp4 instead of caf
            NSTimeInterval duration = [[SoundFileImageController sharedInstance] getFileDuration:file];
            
            // Copy the sound
            NSString* dstPath = [dstDir stringByAppendingPathComponent:[file lastPathComponent]];
            [fm copyItemAtPath:file toPath:dstPath error:NULL];
            
            if (duration > 15)
            {
                // Set iOS format to mp4 for long sounds
                ProjectSettings* settings = [AppDelegate appDelegate].projectSettings;
                NSString* relPath = [ResourceManagerUtil relativePathFromAbsolutePath:dstPath];
                [settings setProperty:[NSNumber numberWithInt:kCCBPublishFormatSound_ios_mp4] forRelPath:relPath andKey:@"format_ios_sound"];
            }
            importedFile = YES;
        
        }
        else if ([ext isEqualToString:@"ttf"])
        {
            // Import fonts or other files that should just be copied
            NSString* dstPath = [dstDir stringByAppendingPathComponent:[file lastPathComponent]];
            [fm copyItemAtPath:file toPath:dstPath error:NULL];
            
            importedFile = YES;
        }
    }
    
    return importedFile;
}

+ (BOOL) importResources:(NSArray*) resources intoDir:(NSString*) dstDir
{
    BOOL importedFile = NO;
    
    for (NSString* srcFile in resources)
    {
        importedFile |= [ResourceManager importFile:srcFile intoDir:dstDir];
    }
    
    return importedFile;
}

+ (BOOL) moveResourceFile:(NSString*)srcPath ofType:(int) type toDirectory:(NSString*) dstDir
{
    if (!dstDir) return NO;
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSString* fileName = [srcPath lastPathComponent];
    
    NSString* dstPath = [dstDir stringByAppendingPathComponent:fileName];
    
    if (type == kCCBResTypeImage)
    {
        // Move all resoultions
        for (NSString* resDir in [ResourceManager resIndependentDirs])
        {
            NSString* srcDir = [srcPath stringByDeletingLastPathComponent];
            NSString* srcResDir = [srcDir stringByAppendingPathComponent:resDir];
            NSString* srcResFile = [srcResDir stringByAppendingPathComponent:fileName];
            
            if ([fm fileExistsAtPath:srcResFile])
            {
                // Create dir if it's not existing already
                NSString* dstResDir = [dstDir stringByAppendingPathComponent:resDir];
                [fm createDirectoryAtPath:dstResDir withIntermediateDirectories:YES attributes:NULL error:NULL];
                
                // Move the file
                NSString* dstResFile = [dstResDir stringByAppendingPathComponent:fileName];
                [fm moveItemAtPath:srcResFile toPath:dstResFile error:NULL];
            }
        }
    }
    else
    {
        // Move regular resources
        [fm moveItemAtPath:srcPath toPath:dstPath error:NULL];
        
        // Also attempt to move preview image (if any)
        NSString* srcPathPre = [srcPath stringByAppendingPathExtension:@"ppng"];
        NSString* dstPathPre = [dstPath stringByAppendingPathExtension:@"ppng"];
        [fm moveItemAtPath:srcPathPre toPath:dstPathPre error:NULL];
    }
    
    // Make sure the project is updated
    NSString* srcRel = [ResourceManagerUtil relativePathFromAbsolutePath:srcPath];
    NSString* dstRel = [ResourceManagerUtil relativePathFromAbsolutePath:dstPath];
    
    [[AppDelegate appDelegate].projectSettings movedResourceFrom:srcRel to:dstRel];
    [[AppDelegate appDelegate] renamedDocumentPathFrom:srcPath to:dstPath];
    
    // Update resources
    [[ResourceManager sharedManager] reloadAllResources];
    
    return YES;
}

+ (BOOL)fileRename:(NSString *)srcPath dstPath:(NSString *)dstPath error:(NSError **)error
{
	NSFileManager* fm = [NSFileManager defaultManager];

	if ([[srcPath stringByDeletingLastPathComponent] isEqualToString:[dstPath stringByDeletingLastPathComponent]]
		&& ([[srcPath lastPathComponent] compare:[dstPath lastPathComponent] options:NSCaseInsensitiveSearch] == NSOrderedSame))
	{
		NSString *tmpFilename = [[NSProcessInfo processInfo] globallyUniqueString];
		NSString *tmpPath = [[srcPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:tmpFilename];

		BOOL resultTmp = [fm moveItemAtPath:srcPath toPath:tmpPath error:error];
		return resultTmp && [fm moveItemAtPath:tmpPath toPath:dstPath error:error];
	}

	return [fm moveItemAtPath:srcPath toPath:dstPath error:error];
}

+ (void) renameResourceFile:(NSString*)srcPath toNewName:(NSString*) newName
{
    NSString* dstPath = [[srcPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newName];
    int type = [ResourceManager getResourceTypeForFile:srcPath];
    
    if (type == kCCBResTypeImage)
    {
        // Rename all resolutions
        NSString* srcDir = [srcPath stringByDeletingLastPathComponent];
        NSString* oldName = [srcPath lastPathComponent];
        
        for (NSString* resDir in [ResourceManager resIndependentDirs])
        {
            NSString* srcResPath = [[srcDir stringByAppendingPathComponent:resDir] stringByAppendingPathComponent:oldName];
            NSString* dstResPath = [[srcDir stringByAppendingPathComponent:resDir] stringByAppendingPathComponent:newName];
            
            // Move the file
			[ResourceManager fileRename:srcResPath dstPath:dstResPath error:NULL];
        }
    }
    else
    {
        // Move file
		[ResourceManager fileRename:srcPath  dstPath:dstPath error:NULL];

        // Also attempt to move preview image (if any)
        NSString* srcPathPre = [srcPath stringByAppendingPathExtension:@"ppng"];
        NSString* dstPathPre = [dstPath stringByAppendingPathExtension:@"ppng"];

		[ResourceManager fileRename:srcPathPre dstPath:dstPathPre error:NULL];
    }
    
    // Make sure the project is updated
    NSString* srcRel = [ResourceManagerUtil relativePathFromAbsolutePath:srcPath];
    NSString* dstRel = [ResourceManagerUtil relativePathFromAbsolutePath:dstPath];
    
    [[AppDelegate appDelegate].projectSettings movedResourceFrom:srcRel to:dstRel];
    [[AppDelegate appDelegate] renamedDocumentPathFrom:srcPath to:dstPath];
    
    // Update resources
    [[ResourceManager sharedManager] reloadAllResources];
}

+ (void) removeResource:(RMResource*) res
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    
    NSString* dirPath = [res.filePath stringByDeletingLastPathComponent];
    NSString* fileName = [res.filePath lastPathComponent];
    
    if (res.type == kCCBResTypeImage)
    {
        // Remove all resolutions
        NSArray* resolutions = [ResourceManager resIndependentDirs];
        for (NSString* resolution in resolutions)
        {
            NSString* filePath = [[dirPath stringByAppendingPathComponent:resolution] stringByAppendingPathComponent:fileName];
            [fm removeItemAtPath:filePath error:NULL];
        }
    }
    else
    {
        // Just remove the file
        [fm removeItemAtPath:res.filePath error:NULL];
        
        // Also attempt to remove preview image (if any)
        NSString* filePathPre = [res.filePath stringByAppendingPathExtension:@"ppng"];
        [fm removeItemAtPath:filePathPre error:NULL];
    }
    
    // Make sure it is removed from the current project
    [[AppDelegate appDelegate].projectSettings removedResourceAt:res.relativePath];
    [[AppDelegate appDelegate] removedDocumentWithPath:res.filePath];
}

+ (void) touchResource:(RMResource*) res
{
    if (res.type == kCCBResTypeImage)
    {
        for (NSString* resDir in [ResourceManager resIndependentDirs])
        {
            NSString* fileName = [res.filePath lastPathComponent];
            NSString* resPath = [[[res.filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:resDir ] stringByAppendingPathComponent:fileName];
            
            [CCBFileUtil setModificationDate:[NSDate date] forFile:resPath];
        }
    }
    else
    {
        [CCBFileUtil setModificationDate:[NSDate date] forFile:res.filePath];
    }
}

- (RMResource*) resourceForPath:(NSString*) path inDir:(RMDirectory*) dir
{
    for (RMResource* res in dir.any)
    {
        if ([res.filePath isEqualToString:path])
        {
            return res;
        }
        
        if (res.type == kCCBResTypeDirectory)
        {
            RMDirectory* subDir = res.data;
            RMResource* found = [self resourceForPath:path inDir:subDir];
            if (found)
            {
                return found;
            }
        }
    }
    return NULL;
}

- (RMResource*) resourceForPath:(NSString*) path
{
    // Find resource for path
    for (RMDirectory* dir in activeDirectories)
    {
        RMResource* res = [self resourceForPath:path inDir:dir];
        if (res) return res;
    }
    return NULL;
}

- (RMDirectory *)directoryForPath:(NSString *)fullPath
{
    for (RMDirectory*directory in activeDirectories)
    {
        if ([directory.dirPath isEqualToString:fullPath])
        {
            return directory;
        }
    }
    return nil;
}


#pragma mark - Locating resources

- (NSString *)dirPathWithFirstDirFallbackForResource:(id)resource
{
    NSString *dirPath = [self dirPathForResource:resource];

    // Find directory
    NSArray *dirs = self.activeDirectories;
    if (dirs.count == 0)
    {
        return nil;
    }

    RMDirectory *dir = [dirs objectAtIndex:0];
    if (!dirPath)
    {
        dirPath = dir.dirPath;
    }
    return dirPath;
}

- (NSString *)dirPathForResource:(id)resource
{
    NSString *dirPath;
    if ([resource isKindOfClass:[RMDirectory class]])
    {
        RMDirectory *directoryResource = (RMDirectory *) resource;
        dirPath = directoryResource.dirPath;

    }
    else if ([resource isKindOfClass:[RMResource class]])
    {
        RMResource *aResource = (RMResource *) resource;
        if (aResource.type == kCCBResTypeDirectory)
        {
            dirPath = aResource.filePath;
        }
        else
        {
            dirPath = [aResource.filePath stringByDeletingLastPathComponent];
        }
    }
    return dirPath;
}


#pragma mark Debug

- (void) debugPrintDirectories
{
    NSLog(@"directories: %@", directories);
    NSLog(@"activeDirectories: %@", activeDirectories);
}

@end
