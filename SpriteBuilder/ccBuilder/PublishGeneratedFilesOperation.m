#import "PublishGeneratedFilesOperation.h"
#import "CCBPublisher.h"
#import "CCBWarnings.h"
#import "CCBPublisherTemplate.h"
#import "CCBFileUtil.h"
#import "ProjectSettings+Convenience.h"


@implementation PublishGeneratedFilesOperation

- (void)main
{
    NSLog(@"[%@]", [self class]);

    [self publishGeneratedFiles];

    [_publisher operationFinishedTick];
}

- (void)publishGeneratedFiles
{
    // Create the directory if it doesn't exist
    BOOL createdDirs = [[NSFileManager defaultManager] createDirectoryAtPath:_outputDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    if (!createdDirs)
    {
        [_warnings addWarningWithDescription:@"Failed to create output directory %@" isFatal:YES];
        return;
    }

    if (_targetType == kCCBPublisherTargetTypeIPhone
        || _targetType == kCCBPublisherTargetTypeAndroid)
    {
        [self generateMainJSFile];
    }
    else if (_targetType == kCCBPublisherTargetTypeHTML5)
    {
        [self generateHTML5Files];
    }

    [self generateFileLookup];

    [self generateSpriteSheetLookup];

    [self generateCocos2dSetupFile];

}

- (void)generateHTML5Files
{
    [self generateIndexHTML5File];

    [self generateBootHTML5Files];

    [self generateMainHTML5File];

    [self generateResourceHTML5File];

    // Copy cocos2d.min.js file
    NSString *cocos2dlibFile = [_outputDir stringByAppendingPathComponent:@"cocos2d-html5.min.js"];
    NSString *cocos2dlibFileSrc = [[NSBundle mainBundle] pathForResource:@"cocos2d.min.txt" ofType:@"" inDirectory:@"publishTemplates"];

    [[NSFileManager defaultManager] copyItemAtPath:cocos2dlibFileSrc toPath:cocos2dlibFile error:NULL];
}

- (void)generateMainHTML5File
{
    NSString* mainFile = [_outputDir stringByAppendingPathComponent:@"main.js"];

    CCBPublisherTemplate *tmpl= [CCBPublisherTemplate templateWithFile:@"main-html5.txt"];
    [tmpl writeToFile:mainFile];
}

- (void)generateResourceHTML5File
{
    NSString* resourceListFile = [_outputDir stringByAppendingPathComponent:@"resources-html5.js"];

    NSString* resourceListStr = @"var ccb_resources = [\n";
    int resCount = 0;
    for (NSString* res in _publishedResources)
    {
        NSString *comma = @",";
        if (resCount == [_publishedResources count] - 1)
        {
            comma = @"";
        }

        NSString *type = NULL;
        NSString *ext = [[res pathExtension] lowercaseString];
        if ([ext isEqualToString:@"plist"])
        {
            type = @"plist";
        }
        else if ([ext isEqualToString:@"png"])
        {
            type = @"image";
        }
        else if ([ext isEqualToString:@"jpg"])
        {
            type = @"image";
        }
        else if ([ext isEqualToString:@"jpeg"])
        {
            type = @"image";
        }
        else if ([ext isEqualToString:@"mp3"])
        {
            type = @"sound";
        }
        else if ([ext isEqualToString:@"ccbi"])
        {
            type = @"ccbi";
        }
        else if ([ext isEqualToString:@"fnt"])
        {
            type = @"fnt";
        }

        if (type)
        {
            resourceListStr = [resourceListStr stringByAppendingFormat:@"    {type:'%@', src:\"%@\"}%@\n", type, res, comma];
        }
    }

    resourceListStr = [resourceListStr stringByAppendingString:@"];\n"];

    [resourceListStr writeToFile:resourceListFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

- (void)generateBootHTML5Files
{
    NSString* bootFile = [_outputDir stringByAppendingPathComponent:@"boot-html5.js"];
    NSArray* jsFiles = [CCBFileUtil filesInResourcePathsWithExtension:@"js"];

    CCBPublisherTemplate *tmpl = [CCBPublisherTemplate templateWithFile:@"boot-html5.txt"];
    [tmpl setStrings:jsFiles forMarker:@"REQUIRED_FILES" prefix:@"    '" suffix:@"',\n"];

    [tmpl writeToFile:bootFile];

    // Generate boot2-html5.js file

    NSString* boot2File = [_outputDir stringByAppendingPathComponent:@"boot2-html5.js"];

    tmpl = [CCBPublisherTemplate templateWithFile:@"boot2-html5.txt"];
    [tmpl setString:_projectSettings.javascriptMainCCB forMarker:@"MAIN_SCENE"];
    [tmpl setString:[NSString stringWithFormat:@"%d", _projectSettings.publishResolutionHTML5_scale] forMarker:@"RESOLUTION_SCALE"];

    [tmpl writeToFile:boot2File];
}

- (void)generateIndexHTML5File
{
    NSString* indexFile = [_outputDir stringByAppendingPathComponent:@"index.html"];

    CCBPublisherTemplate* tmpl = [CCBPublisherTemplate templateWithFile:@"index-html5.txt"];
    [tmpl setString:[NSString stringWithFormat:@"%d", _projectSettings.publishResolutionHTML5_width] forMarker:@"WIDTH"];
    [tmpl setString:[NSString stringWithFormat:@"%d", _projectSettings.publishResolutionHTML5_height] forMarker:@"HEIGHT"];

    [tmpl writeToFile:indexFile];
}

- (void)generateMainJSFile
{
    if (_projectSettings.javascriptBased
        && _projectSettings.javascriptMainCCB
        && ![_projectSettings.javascriptMainCCB isEqualToString:@""]
        && ![self fileExistInResourcePaths:@"main.js"])
    {
        // Find all jsFiles
        NSArray *jsFiles = [CCBFileUtil filesInResourcePathsWithExtension:@"js"];
        NSString *mainFile = [_outputDir stringByAppendingPathComponent:@"main.js"];

        // Generate file from template
        CCBPublisherTemplate *tmpl = [CCBPublisherTemplate templateWithFile:@"main-jsb.txt"];
        [tmpl setStrings:jsFiles forMarker:@"REQUIRED_FILES" prefix:@"require(\"" suffix:@"\");\n"];
        [tmpl setString:_projectSettings.javascriptMainCCB forMarker:@"MAIN_SCENE"];

        [tmpl writeToFile:mainFile];
    }
}

- (void)generateCocos2dSetupFile
{
    NSMutableDictionary* configCocos2d = [NSMutableDictionary dictionary];

    NSString* screenMode = @"";
    if (_projectSettings.designTarget == kCCBDesignTargetFixed)
    {
        screenMode = @"CCScreenModeFixed";
    }
    else if (_projectSettings.designTarget == kCCBDesignTargetFlexible)
    {
        screenMode = @"CCScreenModeFlexible";
    }

    [configCocos2d setObject:screenMode forKey:@"CCSetupScreenMode"];

    NSString *screenOrientation = @"";
    if (_projectSettings.defaultOrientation == kCCBOrientationLandscape)
	{
		screenOrientation = @"CCScreenOrientationLandscape";
	}
	else if (_projectSettings.defaultOrientation == kCCBOrientationPortrait)
	{
		screenOrientation = @"CCScreenOrientationPortrait";
	}

    [configCocos2d setObject:screenOrientation forKey:@"CCSetupScreenOrientation"];

    [configCocos2d setObject:[NSNumber numberWithBool:YES] forKey:@"CCSetupTabletScale2X"];

    NSString *configCocos2dFile = [_outputDir stringByAppendingPathComponent:@"configCocos2d.plist"];
    [configCocos2d writeToFile:configCocos2dFile atomically:YES];
}

- (void)generateSpriteSheetLookup
{
    NSMutableDictionary* spriteSheetLookup = [NSMutableDictionary dictionary];

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    [metadata setObject:[NSNumber numberWithInt:1] forKey:@"version"];

    [spriteSheetLookup setObject:metadata forKey:@"metadata"];

    [spriteSheetLookup setObject:[_publishedSpriteSheetFiles allObjects] forKey:@"spriteFrameFiles"];

    NSString* spriteSheetLookupFile = [_outputDir stringByAppendingPathComponent:@"spriteFrameFileList.plist"];

    [spriteSheetLookup writeToFile:spriteSheetLookupFile atomically:YES];
}

- (void)generateFileLookup
{
    NSMutableDictionary* fileLookup = [NSMutableDictionary dictionary];

    NSMutableDictionary* metadata = [NSMutableDictionary dictionary];
    [metadata setObject:[NSNumber numberWithInt:1] forKey:@"version"];

    [fileLookup setObject:metadata forKey:@"metadata"];
    [fileLookup setObject:_renamedFiles forKey:@"filenames"];

    NSString* lookupFile = [_outputDir stringByAppendingPathComponent:@"fileLookup.plist"];
    [fileLookup writeToFile:lookupFile atomically:YES];
}

- (BOOL) fileExistInResourcePaths:(NSString*)fileName
{
    for (NSString* dir in _projectSettings.absoluteResourcePaths)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[dir stringByAppendingPathComponent:fileName]])
        {
            return YES;
        }
    }
    return NO;
}

@end