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

#import "ProjectSettings.h"
#import "NSString+RelativePath.h"
#import "HashValue.h"
#import "PlugInManager.h"
#import "PlugInExport.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "AppDelegate.h"
#import "ResourceManagerOutlineHandler.h"

#import <ApplicationServices/ApplicationServices.h>

@implementation ProjectSettings

@synthesize projectPath;
@synthesize resourcePaths;
@synthesize publishDirectory;
@synthesize publishDirectoryAndroid;
@synthesize publishDirectoryHTML5;
@synthesize publishEnablediPhone;
@synthesize publishEnabledAndroid;
@synthesize publishEnabledHTML5;
@synthesize publishResolution_ios_phone;
@synthesize publishResolution_ios_phonehd;
@synthesize publishResolution_ios_tablet;
@synthesize publishResolution_ios_tablethd;
@synthesize publishResolution_android_phone;
@synthesize publishResolution_android_phonehd;
@synthesize publishResolution_android_tablet;
@synthesize publishResolution_android_tablethd;
@synthesize publishResolutionHTML5_width;
@synthesize publishResolutionHTML5_height;
@synthesize publishResolutionHTML5_scale;
@synthesize publishAudioQuality_ios;
@synthesize publishAudioQuality_android;
@synthesize isSafariExist;
@synthesize isChromeExist;
@synthesize isFirefoxExist;
@synthesize flattenPaths;
@synthesize publishToZipFile;
@synthesize javascriptBased;
@synthesize javascriptMainCCB;
@synthesize onlyPublishCCBs;
@synthesize exporter;
@synthesize availableExporters;
@synthesize deviceOrientationPortrait;
@synthesize deviceOrientationUpsideDown;
@synthesize deviceOrientationLandscapeLeft;
@synthesize deviceOrientationLandscapeRight;
@synthesize resourceAutoScaleFactor;
@synthesize versionStr;
@synthesize needRepublish;
@synthesize lastWarnings;

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    resourcePaths = [[NSMutableArray alloc] init];
    [resourcePaths addObject:[NSMutableDictionary dictionaryWithObject:@"Resources" forKey:@"path"]];
    self.publishDirectory = @"Published-iOS";
    self.publishDirectoryAndroid = @"Published-Android";
    self.publishDirectoryHTML5 = @"Published-HTML5";
    self.onlyPublishCCBs = NO;
    self.flattenPaths = NO;
    self.javascriptBased = YES;
    self.publishToZipFile = NO;
    self.javascriptMainCCB = @"MainScene";
    self.deviceOrientationLandscapeLeft = YES;
    self.deviceOrientationLandscapeRight = YES;
    self.resourceAutoScaleFactor = 4;
    
    self.publishEnablediPhone = YES;
    self.publishEnabledAndroid = YES;
    self.publishEnabledHTML5 = NO;
    
    self.publishResolution_ios_phone = YES;
    self.publishResolution_ios_phonehd = YES;
    self.publishResolution_ios_tablet = YES;
    self.publishResolution_ios_tablethd = YES;
    self.publishResolution_android_phone = YES;
    self.publishResolution_android_phonehd = YES;
    self.publishResolution_android_tablet = YES;
    self.publishResolution_android_tablethd = YES;
    
    self.publishResolutionHTML5_width = 480;
    self.publishResolutionHTML5_height = 320;
    self.publishResolutionHTML5_scale = 1;
    
    self.publishAudioQuality_ios = 4;
    self.publishAudioQuality_android = 4;
    
    self.tabletPositionScaleFactor = 2.0f;
    
    resourceProperties = [NSMutableDictionary dictionary];
    
    // Load available exporters
    self.availableExporters = [NSMutableArray array];
    for (PlugInExport* plugIn in [[PlugInManager sharedManager] plugInsExporters])
    {
        [availableExporters addObject: plugIn.extension];
    }
    
    [self detectBrowserPresence];
    self.versionStr = [self getVersion];
    self.needRepublish = NO;
    return self;
}

- (id) initWithSerialization:(id)dict
{
    self = [self init];
    if (!self) return NULL;
    
    // Check filetype
    if (![[dict objectForKey:@"fileType"] isEqualToString:@"CocosBuilderProject"])
    {
        return NULL;
    }
    
    // Read settings
    self.resourcePaths = [dict objectForKey:@"resourcePaths"];
    self.publishDirectory = [dict objectForKey:@"publishDirectory"];
    self.publishDirectoryAndroid = [dict objectForKey:@"publishDirectoryAndroid"];
    self.publishDirectoryHTML5 = [dict objectForKey:@"publishDirectoryHTML5"];
    
    if (!publishDirectory) self.publishDirectory = @"";
    if (!publishDirectoryAndroid) self.publishDirectoryAndroid = @"";
    if (!publishDirectoryHTML5) self.publishDirectoryHTML5 = @"";
    
    self.publishEnablediPhone = [[dict objectForKey:@"publishEnablediPhone"] boolValue];
    self.publishEnabledAndroid = [[dict objectForKey:@"publishEnabledAndroid"] boolValue];
    self.publishEnabledHTML5 = [[dict objectForKey:@"publishEnabledHTML5"] boolValue];
    
    self.publishResolution_ios_phone = [[dict objectForKey:@"publishResolution_ios_phone"] boolValue];
    self.publishResolution_ios_phonehd = [[dict objectForKey:@"publishResolution_ios_phonehd"] boolValue];
    self.publishResolution_ios_tablet = [[dict objectForKey:@"publishResolution_ios_tablet"] boolValue];
    self.publishResolution_ios_tablethd = [[dict objectForKey:@"publishResolution_ios_tablethd"] boolValue];
    self.publishResolution_android_phone = [[dict objectForKey:@"publishResolution_android_phone"] boolValue];
    self.publishResolution_android_phonehd = [[dict objectForKey:@"publishResolution_android_phonehd"] boolValue];
    self.publishResolution_android_tablet = [[dict objectForKey:@"publishResolution_android_tablet"] boolValue];
    self.publishResolution_android_tablethd = [[dict objectForKey:@"publishResolution_android_tablethd"] boolValue];
    
    self.publishResolutionHTML5_width = [[dict objectForKey:@"publishResolutionHTML5_width"]intValue];
    self.publishResolutionHTML5_height = [[dict objectForKey:@"publishResolutionHTML5_height"]intValue];
    self.publishResolutionHTML5_scale = [[dict objectForKey:@"publishResolutionHTML5_scale"]intValue];
    if (!publishResolutionHTML5_width) publishResolutionHTML5_width = 960;
    if (!publishResolutionHTML5_height) publishResolutionHTML5_height = 640;
    if (!publishResolutionHTML5_scale) publishResolutionHTML5_scale = 2;
    
    self.publishAudioQuality_ios = [[dict objectForKey:@"publishAudioQuality_ios"]intValue];
    if (!self.publishAudioQuality_ios) self.publishAudioQuality_ios = 1;
    self.publishAudioQuality_android = [[dict objectForKey:@"publishAudioQuality_android"]intValue];
    if (!self.publishAudioQuality_android) self.publishAudioQuality_android = 1;
    
    self.flattenPaths = [[dict objectForKey:@"flattenPaths"] boolValue];
    self.publishToZipFile = [[dict objectForKey:@"publishToZipFile"] boolValue];
    self.javascriptBased = [[dict objectForKey:@"javascriptBased"] boolValue];
    self.onlyPublishCCBs = [[dict objectForKey:@"onlyPublishCCBs"] boolValue];
    self.exporter = [dict objectForKey:@"exporter"];
    self.deviceOrientationPortrait = [[dict objectForKey:@"deviceOrientationPortrait"] boolValue];
    self.deviceOrientationUpsideDown = [[dict objectForKey:@"deviceOrientationUpsideDown"] boolValue];
    self.deviceOrientationLandscapeLeft = [[dict objectForKey:@"deviceOrientationLandscapeLeft"] boolValue];
    self.deviceOrientationLandscapeRight = [[dict objectForKey:@"deviceOrientationLandscapeRight"] boolValue];
    self.resourceAutoScaleFactor = [[dict objectForKey:@"resourceAutoScaleFactor"]intValue];
    if (resourceAutoScaleFactor == 0) self.resourceAutoScaleFactor = 4;
    
    self.deviceScaling = [[dict objectForKey:@"deviceScaling"] intValue];
    self.defaultOrientation = [[dict objectForKey:@"defaultOrientation"] intValue];
    self.designTarget = [[dict objectForKey:@"designTarget"] intValue];
    
    self.tabletPositionScaleFactor = 2.0f;
    
    NSString* mainCCB = [dict objectForKey:@"javascriptMainCCB"];
    if (!mainCCB) mainCCB = @"";
    self.javascriptMainCCB = mainCCB;
    
    // Load resource properties
    resourceProperties = [[dict objectForKey:@"resourceProperties"] mutableCopy];
    
    [self detectBrowserPresence];
    
    // Check if we are running a new version of CocosBuilder
    // in which case the project needs to be republished
    NSString* oldVersionHash = [dict objectForKey:@"versionStr"];
    NSString* newVersionHash = [self getVersion];
    if (newVersionHash && ![newVersionHash isEqual:oldVersionHash])
    {
       self.versionStr = [self getVersion];
       self.needRepublish = YES;
    }
    else
    {
       self.needRepublish = NO;
    }
    
    return self;
}


- (NSString*) exporter
{
    if (exporter) return exporter;
    return kCCBDefaultExportPlugIn;
}

- (id) serialize
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    [dict setObject:@"CocosBuilderProject" forKey:@"fileType"];
    [dict setObject:[NSNumber numberWithInt:kCCBProjectSettingsVersion] forKey:@"fileVersion"];
    [dict setObject:resourcePaths forKey:@"resourcePaths"];
    
    [dict setObject:publishDirectory forKey:@"publishDirectory"];
    [dict setObject:publishDirectoryAndroid forKey:@"publishDirectoryAndroid"];
    [dict setObject:publishDirectoryHTML5 forKey:@"publishDirectoryHTML5"];
    
    [dict setObject:[NSNumber numberWithBool:publishEnablediPhone] forKey:@"publishEnablediPhone"];
    [dict setObject:[NSNumber numberWithBool:publishEnabledAndroid] forKey:@"publishEnabledAndroid"];
    [dict setObject:[NSNumber numberWithBool:publishEnabledHTML5] forKey:@"publishEnabledHTML5"];
    
    
    [dict setObject:[NSNumber numberWithBool:publishResolution_ios_phone] forKey:@"publishResolution_ios_phone"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_ios_phonehd] forKey:@"publishResolution_ios_phonehd"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_ios_tablet] forKey:@"publishResolution_ios_tablet"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_ios_tablethd] forKey:@"publishResolution_ios_tablethd"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_android_phone] forKey:@"publishResolution_android_phone"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_android_phonehd] forKey:@"publishResolution_android_phonehd"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_android_tablet] forKey:@"publishResolution_android_tablet"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_android_tablethd] forKey:@"publishResolution_android_tablethd"];
    
    [dict setObject:[NSNumber numberWithInt:publishResolutionHTML5_width] forKey:@"publishResolutionHTML5_width"];
    [dict setObject:[NSNumber numberWithInt:publishResolutionHTML5_height] forKey:@"publishResolutionHTML5_height"];
    [dict setObject:[NSNumber numberWithInt:publishResolutionHTML5_scale] forKey:@"publishResolutionHTML5_scale"];
    
    [dict setObject:[NSNumber numberWithInt:publishAudioQuality_ios] forKey:@"publishAudioQuality_ios"];
    [dict setObject:[NSNumber numberWithInt:publishAudioQuality_android] forKey:@"publishAudioQuality_android"];
    
    [dict setObject:[NSNumber numberWithBool:flattenPaths] forKey:@"flattenPaths"];
    [dict setObject:[NSNumber numberWithBool:publishToZipFile] forKey:@"publishToZipFile"];
    [dict setObject:[NSNumber numberWithBool:javascriptBased] forKey:@"javascriptBased"];
    [dict setObject:[NSNumber numberWithBool:onlyPublishCCBs] forKey:@"onlyPublishCCBs"];
    [dict setObject:self.exporter forKey:@"exporter"];
    
    [dict setObject:[NSNumber numberWithBool:deviceOrientationPortrait] forKey:@"deviceOrientationPortrait"];
    [dict setObject:[NSNumber numberWithBool:deviceOrientationUpsideDown] forKey:@"deviceOrientationUpsideDown"];
    [dict setObject:[NSNumber numberWithBool:deviceOrientationLandscapeLeft] forKey:@"deviceOrientationLandscapeLeft"];
    [dict setObject:[NSNumber numberWithBool:deviceOrientationLandscapeRight] forKey:@"deviceOrientationLandscapeRight"];
    [dict setObject:[NSNumber numberWithInt:resourceAutoScaleFactor] forKey:@"resourceAutoScaleFactor"];
    
    [dict setObject:[NSNumber numberWithInt:self.designTarget] forKey:@"designTarget"];
    [dict setObject:[NSNumber numberWithInt:self.defaultOrientation] forKey:@"defaultOrientation"];
    [dict setObject:[NSNumber numberWithInt:self.deviceScaling] forKey:@"deviceScaling"];
    
    if (!javascriptMainCCB) self.javascriptMainCCB = @"";
    if (!javascriptBased) self.javascriptMainCCB = @"";
    [dict setObject:javascriptMainCCB forKey:@"javascriptMainCCB"];
    
    if (resourceProperties)
    {
        [dict setObject:resourceProperties forKey:@"resourceProperties"];
    }
    else
    {
        [dict setObject:[NSDictionary dictionary] forKey:@"resourceProperties"];
    }

    if (versionStr)
    {
        [dict setObject:versionStr forKey:@"versionStr"];
    }
    
    [dict setObject:[NSNumber numberWithBool:needRepublish] forKey:@"needRepublish"];
    return dict;
}

- (NSArray*) absoluteResourcePaths
{
    NSString* projectDirectory = [self.projectPath stringByDeletingLastPathComponent];
    
    NSMutableArray* paths = [NSMutableArray array];
    
    for (NSDictionary* dict in resourcePaths)
    {
        NSString* path = [dict objectForKey:@"path"];
        NSString* absPath = [path absolutePathFromBaseDirPath:projectDirectory];
        [paths addObject:absPath];
    }
    
    if ([paths count] == 0)
    {
        [paths addObject:projectDirectory];
    }
    
    return paths;
}

- (NSString*) projectPathHashed
{
    if (projectPath)
    {
        HashValue* hash = [HashValue md5HashWithString:projectPath];
        return [hash description];
    }
    else
    {
        return NULL;
    }
}

- (NSString*) displayCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[[[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"] stringByAppendingPathComponent:@"display"]stringByAppendingPathComponent:self.projectPathHashed];
}

/*
- (NSString*) publishCacheDirectory
{
    NSString* uuid = [PlayerConnection sharedPlayerConnection].selectedDeviceInfo.uuid;
    NSAssert(uuid, @"No uuid for selected device");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[[[[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"] stringByAppendingPathComponent:@"publish"]stringByAppendingPathComponent:self.projectPathHashed] stringByAppendingPathComponent:uuid];
}*/

- (NSString*) tempSpriteSheetCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"] stringByAppendingPathComponent:@"spritesheet"];
}

- (void) _storeDelayed
{
    [self store];
    storing = NO;
}

- (BOOL) store
{
    return [[self serialize] writeToFile:self.projectPath atomically:YES];
}

- (void) storeDelayed
{
    // Store the file after a short delay
    if (!storing)
    {
        storing = YES;
        [self performSelector:@selector(_storeDelayed) withObject:NULL afterDelay:1];
    }
}

- (void) makeSmartSpriteSheet:(RMResource*) res
{
    NSAssert(res.type == kCCBResTypeDirectory, @"Resource must be directory");
    
    [self setValue:[NSNumber numberWithBool:YES] forResource:res andKey:@"isSmartSpriteSheet"];
    
    [self store];
    [[AppDelegate appDelegate].resManager notifyResourceObserversResourceListUpdated];
    [[AppDelegate appDelegate].projectOutlineHandler updateSelectionPreview];
}

- (void) removeSmartSpriteSheet:(RMResource*) res
{
    NSAssert(res.type == kCCBResTypeDirectory, @"Resource must be directory");
    
    [self removeObjectForResource:res andKey:@"isSmartSpriteSheet"];
    
    [self store];
    [[AppDelegate appDelegate].resManager notifyResourceObserversResourceListUpdated];
    [[AppDelegate appDelegate].projectOutlineHandler updateSelectionPreview];
}

- (void) setValue:(id) val forResource:(RMResource*) res andKey:(id) key
{
    NSString* relPath = res.relativePath;
    [self setValue:val forRelPath:relPath andKey:key];
}

- (void) setValue:(id)val forRelPath:(NSString *)relPath andKey:(id)key
{
    // Create value if it doesn't exist
    NSMutableDictionary* props = [resourceProperties valueForKey:relPath];
    if (!props)
    {
        props = [NSMutableDictionary dictionary];
        [resourceProperties setValue:props forKey:relPath];
    }
    
    // Compare to old value
    id oldValue = [props objectForKey:key];
    if (!(oldValue && [oldValue isEqual:val]))
    {
        // Set the value if it has changed
        [props setValue:val forKey:key];
        
        // Also mark as dirty
        [props setValue:[NSNumber numberWithBool:YES] forKey:@"isDirty"];
        
        [self storeDelayed];
    }
}

- (id) valueForResource:(RMResource*) res andKey:(id) key
{
    NSString* relPath = res.relativePath;
    return [self valueForRelPath:relPath andKey:key];
}

- (id) valueForRelPath:(NSString*) relPath andKey:(id) key
{
    NSMutableDictionary* props = [resourceProperties valueForKey:relPath];
    return [props valueForKey:key];
}

- (void) removeObjectForResource:(RMResource*) res andKey:(id) key
{
    NSString* relPath = res.relativePath;
    [self removeObjectForRelPath:relPath andKey:key];
    
}

- (void) removeObjectForRelPath:(NSString*) relPath andKey:(id) key
{
    NSMutableDictionary* props = [resourceProperties valueForKey:relPath];
    [props removeObjectForKey:key];
    
    [self storeDelayed];
}

- (BOOL) isDirtyResource:(RMResource*) res
{
    return [self isDirtyRelPath:res.relativePath];
}

- (BOOL) isDirtyRelPath:(NSString*) relPath
{
    return [[self valueForRelPath:relPath andKey:@"isDirty"] boolValue];
}

- (void) markAsDirtyResource:(RMResource*) res
{
    [self markAsDirtyRelPath:res.relativePath];
}

- (void) markAsDirtyRelPath:(NSString*) relPath
{
    [self setValue:[NSNumber numberWithBool:YES] forRelPath:relPath andKey:@"isDirty"];
}

- (void) clearAllDirtyMarkers
{
    for (NSString* relPath in resourceProperties)
    {
        [self removeObjectForRelPath:relPath andKey:@"isDirty"];
    }
    
    [self storeDelayed];
}

- (NSArray*) smartSpriteSheetDirectories
{
    NSMutableArray* dirs = [NSMutableArray array];
    for (NSString* relPath in resourceProperties)
    {
        if ([[[resourceProperties objectForKey:relPath] objectForKey:@"isSmartSpriteSheet"] boolValue])
        {
            [dirs addObject:relPath];
        }
    }
    return dirs;
}


- (void) removedResourceAt:(NSString*) relPath
{
    [resourceProperties removeObjectForKey:relPath];
}

- (void) movedResourceFrom:(NSString*) relPathOld to:(NSString*) relPathNew
{
    id props = [resourceProperties objectForKey:relPathOld];
    if (props) [resourceProperties setObject:props forKey:relPathNew];
    [resourceProperties removeObjectForKey:relPathOld];
}

- (void) detectBrowserPresence
{
    isSafariExist = FALSE;
    isChromeExist = FALSE;
    isFirefoxExist = FALSE;
    
    OSStatus result = LSFindApplicationForInfo (kLSUnknownCreator, CFSTR("com.apple.Safari"), NULL, NULL, NULL);
    if (result == noErr)
    {
        isSafariExist = TRUE;
    }
    
    result = LSFindApplicationForInfo (kLSUnknownCreator, CFSTR("com.google.Chrome"), NULL, NULL, NULL);
    if (result == noErr)
    {
        isChromeExist = TRUE;
    }

    result = LSFindApplicationForInfo (kLSUnknownCreator, CFSTR("org.mozilla.firefox"), NULL, NULL, NULL);
    if (result == noErr)
    {
        isFirefoxExist = TRUE;
    }
}

- (NSString* ) getVersion
{
    NSString* versionPath = [[NSBundle mainBundle] pathForResource:@"Version" ofType:@"txt" inDirectory:@"Generated"];
    
    NSString* version = [NSString stringWithContentsOfFile:versionPath encoding:NSUTF8StringEncoding error:NULL];
    return version;
}

@end
