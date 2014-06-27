#import "RMResource.h"/*
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
#import "AppDelegate.h"
#import "ResourceManagerOutlineHandler.h"
#import "CCBWarnings.h"
#import "SBErrors.h"
#import "ResourceTypes.h"
#import "NSError+SBErrors.h"

#import <ApplicationServices/ApplicationServices.h>

@implementation ProjectSettings

@synthesize projectPath;
@synthesize resourcePaths;
@synthesize publishDirectory;
@synthesize publishDirectoryAndroid;
@synthesize publishEnablediPhone;
@synthesize publishEnabledAndroid;
@synthesize publishResolution_ios_phone;
@synthesize publishResolution_ios_phonehd;
@synthesize publishResolution_ios_tablet;
@synthesize publishResolution_ios_tablethd;
@synthesize publishResolution_android_phone;
@synthesize publishResolution_android_phonehd;
@synthesize publishResolution_android_tablet;
@synthesize publishResolution_android_tablethd;
@synthesize publishAudioQuality_ios;
@synthesize publishAudioQuality_android;
@synthesize isSafariExist;
@synthesize isChromeExist;
@synthesize isFirefoxExist;
@synthesize flattenPaths;
@synthesize publishToZipFile;
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

	_engine = CCBTargetEngineCocos2d;

    resourcePaths = [[NSMutableArray alloc] init];
    [resourcePaths addObject:[NSMutableDictionary dictionaryWithObject:@"Resources" forKey:@"path"]];
    self.publishDirectory = @"Published-iOS";
    self.publishDirectoryAndroid = @"Published-Android";
    self.onlyPublishCCBs = NO;
    self.flattenPaths = NO;
    self.publishToZipFile = NO;
    self.deviceOrientationLandscapeLeft = YES;
    self.deviceOrientationLandscapeRight = YES;
    self.resourceAutoScaleFactor = 4;
    
    self.publishEnablediPhone = YES;
    self.publishEnabledAndroid = YES;

    self.publishResolution_ios_phone = YES;
    self.publishResolution_ios_phonehd = YES;
    self.publishResolution_ios_tablet = YES;
    self.publishResolution_ios_tablethd = YES;
    self.publishResolution_android_phone = YES;
    self.publishResolution_android_phonehd = YES;
    self.publishResolution_android_tablet = YES;
    self.publishResolution_android_tablethd = YES;
    
    self.publishEnvironment = PublishEnvironmentDevelop;

    self.publishAudioQuality_ios = 4;
    self.publishAudioQuality_android = 4;
    
    self.tabletPositionScaleFactor = 2.0f;

    self.canUpdateCocos2D = NO;
    self.cocos2dUpdateIgnoredVersions = [NSMutableArray array];
    
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
	_engine = [[dict objectForKey:@"engine"] intValue];

    self.resourcePaths = [dict objectForKey:@"resourcePaths"];
    self.publishDirectory = [dict objectForKey:@"publishDirectory"];
    self.publishDirectoryAndroid = [dict objectForKey:@"publishDirectoryAndroid"];

    if (!publishDirectory) self.publishDirectory = @"";
    if (!publishDirectoryAndroid) self.publishDirectoryAndroid = @"";

    self.publishEnablediPhone = [[dict objectForKey:@"publishEnablediPhone"] boolValue];
    self.publishEnabledAndroid = [[dict objectForKey:@"publishEnabledAndroid"] boolValue];

    self.publishResolution_ios_phone = [[dict objectForKey:@"publishResolution_ios_phone"] boolValue];
    self.publishResolution_ios_phonehd = [[dict objectForKey:@"publishResolution_ios_phonehd"] boolValue];
    self.publishResolution_ios_tablet = [[dict objectForKey:@"publishResolution_ios_tablet"] boolValue];
    self.publishResolution_ios_tablethd = [[dict objectForKey:@"publishResolution_ios_tablethd"] boolValue];
    self.publishResolution_android_phone = [[dict objectForKey:@"publishResolution_android_phone"] boolValue];
    self.publishResolution_android_phonehd = [[dict objectForKey:@"publishResolution_android_phonehd"] boolValue];
    self.publishResolution_android_tablet = [[dict objectForKey:@"publishResolution_android_tablet"] boolValue];
    self.publishResolution_android_tablethd = [[dict objectForKey:@"publishResolution_android_tablethd"] boolValue];
    
    self.publishAudioQuality_ios = [[dict objectForKey:@"publishAudioQuality_ios"]intValue];
    if (!self.publishAudioQuality_ios) self.publishAudioQuality_ios = 1;
    self.publishAudioQuality_android = [[dict objectForKey:@"publishAudioQuality_android"]intValue];
    if (!self.publishAudioQuality_android) self.publishAudioQuality_android = 1;
    
    self.flattenPaths = [[dict objectForKey:@"flattenPaths"] boolValue];
    self.publishToZipFile = [[dict objectForKey:@"publishToZipFile"] boolValue];
    self.onlyPublishCCBs = [[dict objectForKey:@"onlyPublishCCBs"] boolValue];
    self.exporter = [dict objectForKey:@"exporter"];
    self.deviceOrientationPortrait = [[dict objectForKey:@"deviceOrientationPortrait"] boolValue];
    self.deviceOrientationUpsideDown = [[dict objectForKey:@"deviceOrientationUpsideDown"] boolValue];
    self.deviceOrientationLandscapeLeft = [[dict objectForKey:@"deviceOrientationLandscapeLeft"] boolValue];
    self.deviceOrientationLandscapeRight = [[dict objectForKey:@"deviceOrientationLandscapeRight"] boolValue];
    self.resourceAutoScaleFactor = [[dict objectForKey:@"resourceAutoScaleFactor"]intValue];
    if (resourceAutoScaleFactor == 0) self.resourceAutoScaleFactor = 4;

    self.cocos2dUpdateIgnoredVersions = [[dict objectForKey:@"cocos2dUpdateIgnoredVersions"] mutableCopy];

    self.deviceScaling = [[dict objectForKey:@"deviceScaling"] intValue];
    self.defaultOrientation = [[dict objectForKey:@"defaultOrientation"] intValue];
    self.designTarget = [[dict objectForKey:@"designTarget"] intValue];
    
    self.tabletPositionScaleFactor = 2.0f;

    self.publishEnvironment = [[dict objectForKey:@"publishEnvironment"] integerValue];

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

	[dict setObject:[NSNumber numberWithInt:_engine] forKey:@"engine"];

    [dict setObject:@"CocosBuilderProject" forKey:@"fileType"];
    [dict setObject:[NSNumber numberWithInt:kCCBProjectSettingsVersion] forKey:@"fileVersion"];
    [dict setObject:resourcePaths forKey:@"resourcePaths"];
    
    [dict setObject:publishDirectory forKey:@"publishDirectory"];
    [dict setObject:publishDirectoryAndroid forKey:@"publishDirectoryAndroid"];

    [dict setObject:[NSNumber numberWithBool:publishEnablediPhone] forKey:@"publishEnablediPhone"];
    [dict setObject:[NSNumber numberWithBool:publishEnabledAndroid] forKey:@"publishEnabledAndroid"];

    [dict setObject:[NSNumber numberWithBool:publishResolution_ios_phone] forKey:@"publishResolution_ios_phone"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_ios_phonehd] forKey:@"publishResolution_ios_phonehd"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_ios_tablet] forKey:@"publishResolution_ios_tablet"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_ios_tablethd] forKey:@"publishResolution_ios_tablethd"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_android_phone] forKey:@"publishResolution_android_phone"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_android_phonehd] forKey:@"publishResolution_android_phonehd"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_android_tablet] forKey:@"publishResolution_android_tablet"];
    [dict setObject:[NSNumber numberWithBool:publishResolution_android_tablethd] forKey:@"publishResolution_android_tablethd"];
    
    [dict setObject:[NSNumber numberWithInt:publishAudioQuality_ios] forKey:@"publishAudioQuality_ios"];
    [dict setObject:[NSNumber numberWithInt:publishAudioQuality_android] forKey:@"publishAudioQuality_android"];
    
    [dict setObject:[NSNumber numberWithBool:flattenPaths] forKey:@"flattenPaths"];
    [dict setObject:[NSNumber numberWithBool:publishToZipFile] forKey:@"publishToZipFile"];
    [dict setObject:[NSNumber numberWithBool:onlyPublishCCBs] forKey:@"onlyPublishCCBs"];
    [dict setObject:self.exporter forKey:@"exporter"];
    
    [dict setObject:[NSNumber numberWithBool:deviceOrientationPortrait] forKey:@"deviceOrientationPortrait"];
    [dict setObject:[NSNumber numberWithBool:deviceOrientationUpsideDown] forKey:@"deviceOrientationUpsideDown"];
    [dict setObject:[NSNumber numberWithBool:deviceOrientationLandscapeLeft] forKey:@"deviceOrientationLandscapeLeft"];
    [dict setObject:[NSNumber numberWithBool:deviceOrientationLandscapeRight] forKey:@"deviceOrientationLandscapeRight"];
    [dict setObject:[NSNumber numberWithInt:resourceAutoScaleFactor] forKey:@"resourceAutoScaleFactor"];

    [dict setObject:_cocos2dUpdateIgnoredVersions forKey:@"cocos2dUpdateIgnoredVersions"];

    [dict setObject:[NSNumber numberWithInt:self.designTarget] forKey:@"designTarget"];
    [dict setObject:[NSNumber numberWithInt:self.defaultOrientation] forKey:@"defaultOrientation"];
    [dict setObject:[NSNumber numberWithInt:self.deviceScaling] forKey:@"deviceScaling"];

    [dict setObject:[NSNumber numberWithInt:self.publishEnvironment] forKey:@"publishEnvironment"];

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

@dynamic absoluteResourcePaths;
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

@dynamic projectPathHashed;
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

@dynamic displayCacheDirectory;
- (NSString*) displayCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[[[paths objectAtIndex:0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"] stringByAppendingPathComponent:@"display"]stringByAppendingPathComponent:self.projectPathHashed];
}

@dynamic tempSpriteSheetCacheDirectory;
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
    [[ResourceManager sharedManager] notifyResourceObserversResourceListUpdated];
    [[AppDelegate appDelegate].projectOutlineHandler updateSelectionPreview];
}

- (void) removeSmartSpriteSheet:(RMResource*) res
{
    NSAssert(res.type == kCCBResTypeDirectory, @"Resource must be directory");
    
    [self removeObjectForResource:res andKey:@"isSmartSpriteSheet"];

    [self removeIntermediateFileLookupFile:res];

    [self store];
    [[ResourceManager sharedManager] notifyResourceObserversResourceListUpdated];
    [[AppDelegate appDelegate].projectOutlineHandler updateSelectionPreview];
}

- (void)removeIntermediateFileLookupFile:(RMResource *)res
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *intermediateFileLookup = [res.filePath stringByAppendingPathComponent:@"intermediateFileLookup.plist"];
    if ([fileManager fileExistsAtPath:intermediateFileLookup])
    {
        NSError *error;
        if (![fileManager removeItemAtPath:intermediateFileLookup error:&error])
        {
            NSLog(@"Error removing intermediate filelookup file %@ - %@", intermediateFileLookup, error);
        }
    }
}

- (void) setValue:(id) val forResource:(RMResource*) res andKey:(id) key
{
    NSString* relPath = res.relativePath;
    [self setValue:val forRelPath:relPath andKey:key];
    [self markAsDirtyResource:res];
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

- (BOOL)removeResourcePath:(NSString *)path error:(NSError **)error
{
    NSString *projectDir = [self.projectPath stringByDeletingLastPathComponent];
    NSString *relResourcePath = [path relativePathFromBaseDirPath:projectDir];

    for (NSMutableDictionary *resourcePath in [resourcePaths copy])
    {
        NSString *relPath = resourcePath[@"path"];
        if ([relPath isEqualToString:relResourcePath])
        {
            [resourcePaths removeObject:resourcePath];
            return YES;
        }
    }

    [NSError setNewErrorWithCode:error
                            code:SBResourcePathNotInProjectError
                         message:[NSString stringWithFormat:@"Cannot remove path \"%@\" does not exist in project.", relResourcePath]];
    return NO;
}

- (BOOL)addResourcePath:(NSString *)path error:(NSError **)error
{
    if (![self isResourcePathInProject:path])
    {
        NSString *relResourcePath = [path relativePathFromBaseDirPath:self.projectPathDir];

        [resourcePaths addObject:[NSMutableDictionary dictionaryWithObject:relResourcePath forKey:@"path"]];
        return YES;
    }
    else
    {
        [NSError setNewErrorWithCode:error code:SBDuplicateResourcePathError message:[NSString stringWithFormat:@"Cannot create %@, already present.", [path lastPathComponent]]];
        return NO;
    }
}

- (BOOL)isResourcePathInProject:(NSString *)resourcePath
{
    NSString *relResourcePath = [resourcePath relativePathFromBaseDirPath:self.projectPathDir];

    return [self resourcePathForRelativePath:relResourcePath] != nil;
}

- (NSMutableDictionary *)resourcePathForRelativePath:(NSString *)path
{
    for (NSMutableDictionary *resourcePath in resourcePaths)
    {
        NSString *aResourcePath = [resourcePath objectForKey:@"path"];
        if ([aResourcePath isEqualToString:path])
        {
            return resourcePath;
        }
    }
    return nil;
}

- (BOOL)moveResourcePathFrom:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error
{
    if ([self isResourcePathInProject:toPath])
    {
        [NSError setNewErrorWithCode:error code:SBDuplicateResourcePathError message:@"Cannot move resource path, there's already one with the same name."];
        return NO;
    }

    NSString *relResourcePathOld = [fromPath relativePathFromBaseDirPath:self.projectPathDir];
    NSString *relResourcePathNew = [toPath relativePathFromBaseDirPath:self.projectPathDir];

    NSMutableDictionary *resourcePath = [self resourcePathForRelativePath:relResourcePathOld];
    resourcePath[@"path"] = relResourcePathNew;

    [self movedResourceFrom:relResourcePathOld to:relResourcePathNew];
    return YES;
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

- (void)setCocos2dUpdateIgnoredVersions:(NSMutableArray *)anArray
{
    if (!anArray)
    {
        _cocos2dUpdateIgnoredVersions = [NSMutableArray array];
    }
    else
    {
        _cocos2dUpdateIgnoredVersions = anArray;
    }
}

-(void) setPublishResolution_ios_phone:(BOOL)publishResolution
{
	if (_engine != CCBTargetEngineSpriteKit)
	{
		publishResolution_ios_phone = publishResolution;
	}
	else
	{
		// Sprite Kit doesn't run on non-Retina phones to begin with...
		publishResolution_ios_phone = NO;
	}
}

- (void)flagFilesDirtyWithWarnings:(CCBWarnings *)warnings
{
	for (CCBWarning *warning in warnings.warnings)
	{
		if (warning.relatedFile)
		{
			[self markAsDirtyRelPath:warning.relatedFile];
		}
	}
}

- (NSString *)projectPathDir
{
    return [projectPath stringByDeletingLastPathComponent];
}

@end
