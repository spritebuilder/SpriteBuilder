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
#import "MiscConstants.h"

#import <ApplicationServices/ApplicationServices.h>

@interface ProjectSettings()

@property (nonatomic, strong) NSMutableDictionary* resourceProperties;
@property (nonatomic, readwrite) CCBTargetEngine engine;
@property (nonatomic) BOOL storing;

@end

@implementation ProjectSettings

- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }

    self.engine = CCBTargetEngineCocos2d;

    self.resourcePaths = [[NSMutableArray alloc] init];
    self.publishDirectory = @"Published-iOS";
    self.publishDirectoryAndroid = @"Published-Android";

    self.onlyPublishCCBs = NO;
    self.publishToZipFile = NO;

    self.deviceOrientationLandscapeLeft = YES;
    self.deviceOrientationLandscapeRight = YES;
    self.resourceAutoScaleFactor = 4;
    
    self.publishEnabledIOS = YES;
    self.publishEnabledAndroid = YES;

    self.publishResolution_ios_phone = YES;
    self.publishResolution_ios_phonehd = YES;
    self.publishResolution_ios_tablet = YES;
    self.publishResolution_ios_tablethd = YES;
    self.publishResolution_android_phone = YES;
    self.publishResolution_android_phonehd = YES;
    self.publishResolution_android_tablet = YES;
    self.publishResolution_android_tablethd = YES;
    
    self.publishEnvironment = kCCBPublishEnvironmentDevelop;

    self.publishAudioQuality_ios = DEFAULT_AUDIO_QUALITY;
    self.publishAudioQuality_android = DEFAULT_AUDIO_QUALITY;
    
    self.tabletPositionScaleFactor = 2.0f;

    self.canUpdateCocos2D = NO;
    self.cocos2dUpdateIgnoredVersions = [NSMutableArray array];
    
    self.resourceProperties = [NSMutableDictionary dictionary];
    
    // Load available exporters
    self.availableExporters = [NSMutableArray array];
    for (PlugInExport* plugIn in [[PlugInManager sharedManager] plugInsExporters])
    {
        [_availableExporters addObject: plugIn.extension];
    }

    self.versionStr = [self getVersion];
    self.needRepublish = NO;

    return self;
}

- (id) initWithSerialization:(id)dict
{
    self = [self init];
    if (!self
        || ![[dict objectForKey:@"fileType"] isEqualToString:@"CocosBuilderProject"])
    {
        return NULL;
    }

	self.engine = (CCBTargetEngine)[[dict objectForKey:@"engine"] intValue];
    self.resourcePaths = [dict objectForKey:@"resourcePaths"];

    self.publishDirectory = [dict objectForKey:@"publishDirectory"];
    if (!_publishDirectory)
    {
        self.publishDirectory = @"";
    }

    self.publishDirectoryAndroid = [dict objectForKey:@"publishDirectoryAndroid"];
    if (!_publishDirectoryAndroid)
    {
        self.publishDirectoryAndroid = @"";
    }

    self.publishEnabledIOS = [[dict objectForKey:@"publishEnablediPhone"] boolValue];
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
    if (!self.publishAudioQuality_ios)
    {
        self.publishAudioQuality_ios = DEFAULT_AUDIO_QUALITY;
    }

    self.publishAudioQuality_android = [[dict objectForKey:@"publishAudioQuality_android"]intValue];
    if (!self.publishAudioQuality_android)
    {
        self.publishAudioQuality_android = DEFAULT_AUDIO_QUALITY;
    }

    self.publishToZipFile = [[dict objectForKey:@"publishToZipFile"] boolValue];
    self.onlyPublishCCBs = [[dict objectForKey:@"onlyPublishCCBs"] boolValue];
    self.exporter = [dict objectForKey:@"exporter"];
    self.deviceOrientationPortrait = [[dict objectForKey:@"deviceOrientationPortrait"] boolValue];
    self.deviceOrientationUpsideDown = [[dict objectForKey:@"deviceOrientationUpsideDown"] boolValue];
    self.deviceOrientationLandscapeLeft = [[dict objectForKey:@"deviceOrientationLandscapeLeft"] boolValue];
    self.deviceOrientationLandscapeRight = [[dict objectForKey:@"deviceOrientationLandscapeRight"] boolValue];

    self.resourceAutoScaleFactor = [[dict objectForKey:@"resourceAutoScaleFactor"]intValue];
    if (_resourceAutoScaleFactor == 0)
    {
        self.resourceAutoScaleFactor = 4;
    }

    self.cocos2dUpdateIgnoredVersions = [[dict objectForKey:@"cocos2dUpdateIgnoredVersions"] mutableCopy];

    self.deviceScaling = [[dict objectForKey:@"deviceScaling"] intValue];
    self.defaultOrientation = [[dict objectForKey:@"defaultOrientation"] intValue];
    self.designTarget = [[dict objectForKey:@"designTarget"] intValue];
    
    self.tabletPositionScaleFactor = 2.0f;

    self.publishEnvironment = (CCBPublishEnvironment) [[dict objectForKey:@"publishEnvironment"] integerValue];

    self.resourceProperties = [[dict objectForKey:@"resourceProperties"] mutableCopy];

    self.excludedFromPackageMigration = [[dict objectForKey:@"excludedFromPackageMigration"] boolValue];
    if (!self.excludedFromPackageMigration)
    {
        self.excludedFromPackageMigration = NO;
    }

    [self initializeVersionStringWithProjectDict:dict];

    return self;
}

- (void)initializeVersionStringWithProjectDict:(NSDictionary *)projectDict
{
    // Check if we are running a new version of CocosBuilder
    // in which case the project needs to be republished
    NSString* oldVersionHash = projectDict[@"versionStr"];
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
}

- (NSString*) exporter
{
    if (_exporter)
    {
        return _exporter;
    }
    return kCCBDefaultExportPlugIn;
}

- (id) serialize
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];

    dict[@"engine"] = @(_engine);

    dict[@"fileType"] = @"CocosBuilderProject";
    dict[@"fileVersion"] = @kCCBProjectSettingsVersion;
    dict[@"resourcePaths"] = _resourcePaths;
    
    dict[@"publishDirectory"] = _publishDirectory;
    dict[@"publishDirectoryAndroid"] = _publishDirectoryAndroid;

    dict[@"publishEnablediPhone"] = @(_publishEnabledIOS);
    dict[@"publishEnabledAndroid"] = @(_publishEnabledAndroid);

    dict[@"publishResolution_ios_phone"] = @(_publishResolution_ios_phone);
    dict[@"publishResolution_ios_phonehd"] = @(_publishResolution_ios_phonehd);
    dict[@"publishResolution_ios_tablet"] = @(_publishResolution_ios_tablet);
    dict[@"publishResolution_ios_tablethd"] = @(_publishResolution_ios_tablethd);
    dict[@"publishResolution_android_phone"] = @(_publishResolution_android_phone);
    dict[@"publishResolution_android_phonehd"] = @(_publishResolution_android_phonehd);
    dict[@"publishResolution_android_tablet"] = @(_publishResolution_android_tablet);
    dict[@"publishResolution_android_tablethd"] = @(_publishResolution_android_tablethd);
    
    dict[@"publishAudioQuality_ios"] = @(_publishAudioQuality_ios);
    dict[@"publishAudioQuality_android"] = @(_publishAudioQuality_android);

    dict[@"publishToZipFile"] = @(_publishToZipFile);
    dict[@"onlyPublishCCBs"] = @(_onlyPublishCCBs);
    dict[@"exporter"] = self.exporter;
    
    dict[@"deviceOrientationPortrait"] = @(_deviceOrientationPortrait);
    dict[@"deviceOrientationUpsideDown"] = @(_deviceOrientationUpsideDown);
    dict[@"deviceOrientationLandscapeLeft"] = @(_deviceOrientationLandscapeLeft);
    dict[@"deviceOrientationLandscapeRight"] = @(_deviceOrientationLandscapeRight);
    dict[@"resourceAutoScaleFactor"] = @(_resourceAutoScaleFactor);

    dict[@"cocos2dUpdateIgnoredVersions"] = _cocos2dUpdateIgnoredVersions;

    dict[@"designTarget"] = @(_designTarget);
    dict[@"defaultOrientation"] = @(_defaultOrientation);
    dict[@"deviceScaling"] = @(_deviceScaling);

    dict[@"publishEnvironment"] = @(_publishEnvironment);

    dict[@"excludedFromPackageMigration"] = @(_excludedFromPackageMigration);

    if (_resourceProperties)
    {
        dict[@"resourceProperties"] = _resourceProperties;
    }
    else
    {
        dict[@"resourceProperties"] = [NSDictionary dictionary];
    }

    if (_versionStr)
    {
        dict[@"versionStr"] = _versionStr;
    }

    return dict;
}

@dynamic absoluteResourcePaths;
- (NSArray*) absoluteResourcePaths
{
    NSString* projectDirectory = [self.projectPath stringByDeletingLastPathComponent];
    
    NSMutableArray* paths = [NSMutableArray array];
    
    for (NSDictionary* dict in _resourcePaths)
    {
        NSString* path = dict[@"path"];
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
    if (_projectPath)
    {
        HashValue* hash = [HashValue md5HashWithString:_projectPath];
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
    return [[[paths[0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"] stringByAppendingPathComponent:@"display"]stringByAppendingPathComponent:self.projectPathHashed];
}

@dynamic tempSpriteSheetCacheDirectory;
- (NSString*) tempSpriteSheetCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [[paths[0] stringByAppendingPathComponent:@"com.cocosbuilder.CocosBuilder"] stringByAppendingPathComponent:@"spritesheet"];
}

- (void) _storeDelayed
{
    [self store];
    self.storing = NO;
}

- (BOOL) store
{
    return [[self serialize] writeToFile:self.projectPath atomically:YES];
}

- (void) storeDelayed
{
    // Store the file after a short delay
    if (!_storing)
    {
        self.storing = YES;
        [self performSelector:@selector(_storeDelayed) withObject:NULL afterDelay:1];
    }
}

- (void) makeSmartSpriteSheet:(RMResource*) res
{
    NSAssert(res.type == kCCBResTypeDirectory, @"Resource must be directory");

    [self setProperty:@YES forResource:res andKey:@"isSmartSpriteSheet"];
    
    [self store];
    [[ResourceManager sharedManager] notifyResourceObserversResourceListUpdated];
    [[AppDelegate appDelegate].projectOutlineHandler updateSelectionPreview];
}

- (void) removeSmartSpriteSheet:(RMResource*) res
{
    NSAssert(res.type == kCCBResTypeDirectory, @"Resource must be directory");

    [self removePropertyForResource:res andKey:@"isSmartSpriteSheet"];

    [self removeIntermediateFileLookupFile:res];

    [self store];
    [[ResourceManager sharedManager] notifyResourceObserversResourceListUpdated];
    [[AppDelegate appDelegate].projectOutlineHandler updateSelectionPreview];
}

- (void)removeIntermediateFileLookupFile:(RMResource *)res
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *intermediateFileLookup = [res.filePath stringByAppendingPathComponent:INTERMEDIATE_FILE_LOOKUP_NAME];
    if ([fileManager fileExistsAtPath:intermediateFileLookup])
    {
        NSError *error;
        if (![fileManager removeItemAtPath:intermediateFileLookup error:&error])
        {
            NSLog(@"Error removing intermediate filelookup file %@ - %@", intermediateFileLookup, error);
        }
    }
}

- (void)setProperty:(id)newValue forResource:(RMResource *)res andKey:(id <NSCopying>) key
{
    NSString* relPath = res.relativePath;
    [self setProperty:newValue forRelPath:relPath andKey:key];
}

- (void)setProperty:(id)newValue forRelPath:(NSString *)relPath andKey:(id <NSCopying>)key
{
    NSMutableDictionary *props = [self resourcePropertiesForRelPath:relPath];

    id oldValue = props[key];
    if ([oldValue isEqual:newValue])
    {
        return;
    }

    [props setValue:newValue forKey:key];
    [self markAsDirtyRelPath:relPath];
    [self storeDelayed];
}

- (NSMutableDictionary *)resourcePropertiesForRelPath:(NSString *)relPath
{
    NSMutableDictionary* props = [_resourceProperties valueForKey:relPath];
    if (!props)
    {
        props = [NSMutableDictionary dictionary];
        [_resourceProperties setValue:props forKey:relPath];
    }
    return props;
}

- (id)propertyForResource:(RMResource *)res andKey:(id <NSCopying>) key
{
    NSString* relPath = [self findRelativePathInPackagesForAbsolutePath:res.filePath];
    return [self propertyForRelPath:relPath andKey:key];
}

- (id)propertyForRelPath:(NSString *)relPath andKey:(id <NSCopying>) key
{
    NSMutableDictionary* props = [_resourceProperties valueForKey:relPath];
    return [props valueForKey:key];
}

- (void)removePropertyForResource:(RMResource *)res andKey:(id <NSCopying>) key
{
    NSString* relPath = res.relativePath;
    [self removePropertyForRelPath:relPath andKey:key];
}

- (void)removePropertyForRelPath:(NSString *)relPath andKey:(id <NSCopying>) key
{
    NSMutableDictionary* props = [_resourceProperties valueForKey:relPath];
    [props removeObjectForKey:key];

    [self markAsDirtyRelPath:relPath];

    [self storeDelayed];
}

- (BOOL) isDirtyResource:(RMResource*) res
{
    return [self isDirtyRelPath:res.relativePath];
}

- (BOOL) isDirtyRelPath:(NSString*) relPath
{
    return [[self propertyForRelPath:relPath andKey:@"isDirty"] boolValue];
}

- (void) markAsDirtyResource:(RMResource*) res
{
    [self markAsDirtyRelPath:res.relativePath];
}

- (void) markAsDirtyRelPath:(NSString*) relPath
{
    [self setProperty:@YES forRelPath:relPath andKey:@"isDirty"];
}

- (void) clearAllDirtyMarkers
{
    for (NSString* relPath in _resourceProperties)
    {
        NSMutableDictionary* props = [_resourceProperties valueForKey:relPath];
        [props removeObjectForKey:@"isDirty"];
    }
    
    [self storeDelayed];
}

- (void) removedResourceAt:(NSString*) relPath
{
    [_resourceProperties removeObjectForKey:relPath];
}

- (void) movedResourceFrom:(NSString*) relPathOld to:(NSString*) relPathNew
{
    id props = _resourceProperties[relPathOld];
    if (props)
    {
        _resourceProperties[relPathNew] = props;
    }
    [_resourceProperties removeObjectForKey:relPathOld];
}

- (BOOL)removeResourcePath:(NSString *)path error:(NSError **)error
{
    NSString *projectDir = [self.projectPath stringByDeletingLastPathComponent];
    NSString *relResourcePath = [path relativePathFromBaseDirPath:projectDir];

    for (NSMutableDictionary *resourcePath in [_resourcePaths copy])
    {
        NSString *relPath = resourcePath[@"path"];
        if ([relPath isEqualToString:relResourcePath])
        {
            [_resourcePaths removeObject:resourcePath];
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

        [_resourcePaths addObject:[@{@"path" : relResourcePath} mutableCopy]];
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
    for (NSMutableDictionary *resourcePath in _resourcePaths)
    {
        NSString *aResourcePath = resourcePath[@"path"];
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

// TODO: remove after transition state to ResourcePath class
- (NSString *)fullPathForResourcePathDict:(NSMutableDictionary *)resourcePathDict
{
    return [self.projectPathDir stringByAppendingPathComponent:resourcePathDict[@"path"]];
}

- (NSString* ) getVersion
{
	NSDictionary * versionDict = [self getVersionDictionary];
	NSString * versionString = @"";
	
	for (NSString * key in versionDict) {
		versionString = [versionString stringByAppendingFormat:@"%@ : %@\n", key, versionDict[key]];
	}
    
    return versionString;
}

- (NSDictionary *)getVersionDictionary
{
	NSString* versionPath = [[NSBundle mainBundle] pathForResource:@"Version" ofType:@"txt" inDirectory:@"Generated"];
	
	NSError * error;
    NSString* version = [NSString stringWithContentsOfFile:versionPath encoding:NSUTF8StringEncoding error:&error];
	
	if(error)
	{
		NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
		NSString* version = [infoDict objectForKey:@"CFBundleVersion"];

		NSMutableDictionary * versionDict = [NSMutableDictionary dictionaryWithDictionary:@{@"version" : version}];
		
#ifdef SPRITEBUILDER_PRO
		versionDict[@"sku"] = @"pro";
#else
		versionDict[@"sku"] = @"default";
#endif
		return versionDict;
		
	}
	else
	{
		NSData* versionData = [version dataUsingEncoding:NSUTF8StringEncoding];
		NSDictionary * versionDict = [NSJSONSerialization JSONObjectWithData:versionData options:0x0 error:&error];
		return versionDict;
	}
}


- (void)setCocos2dUpdateIgnoredVersions:(NSMutableArray *)anArray
{
    _cocos2dUpdateIgnoredVersions = !anArray
        ? [NSMutableArray array]
        : anArray;
}

-(void) setPublishResolution_ios_phone:(BOOL)publishResolution
{
	if (_engine != CCBTargetEngineSpriteKit)
	{
		_publishResolution_ios_phone = publishResolution;
	}
	else
	{
		// Sprite Kit doesn't run on non-Retina phones to begin with...
		_publishResolution_ios_phone = NO;
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
    return [_projectPath stringByDeletingLastPathComponent];
}

- (NSString *)findRelativePathInPackagesForAbsolutePath:(NSString *)absolutePath
{
    for (NSString *absoluteResourcePath in self.absoluteResourcePaths)
    {
        if ([absolutePath hasPrefix:absoluteResourcePath])
        {
            return [absolutePath substringFromIndex:[absoluteResourcePath length] + 1];
        }
    }

    return nil;
}

@end
