#import "PublishGeneratedFilesOperation.h"

#import "CCBPublisherTemplate.h"
#import "CCBFileUtil.h"
#import "ProjectSettings.h"
#import "PublishRenamedFilesLookup.h"
#import "PublishingTaskStatusProgress.h"


@implementation PublishGeneratedFilesOperation

- (void)main
{
    [super main];

    [self assertProperties];

    [self publishGeneratedFiles];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)assertProperties
{
    NSAssert(_outputDir != nil, @"outputDir should not be nil");
    NSAssert(_publishedSpriteSheetFiles != nil, @"publishedSpriteSheetFiles should not be nil");
    NSAssert(_fileLookup != nil, @"fileLookup should not be nil");
}

- (void)publishGeneratedFiles
{
    [_publishingTaskStatusProgress updateStatusText:@"Generating misc files"];

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
        // TODO: Is this actually needed any more?
        [self generateMainJSFile];
    }

    [self generateFileLookup];

    [self generateSpriteFrameFileList];

    [self generateCocos2dSetupFile];
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

// TODO: is this a spriteFrameList or a dictionary for the publishedSpriteSheet files?
- (void)generateSpriteFrameFileList
{
    NSMutableDictionary*spriteFrameFileList = [NSMutableDictionary dictionary];

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    [metadata setObject:[NSNumber numberWithInt:1] forKey:@"version"];

    [spriteFrameFileList setObject:metadata forKey:@"metadata"];
    [spriteFrameFileList setObject:[_publishedSpriteSheetFiles allObjects] forKey:@"spriteFrameFiles"];

    NSString* spriteSheetLookupFile = [_outputDir stringByAppendingPathComponent:@"spriteFrameFileList.plist"];
    [spriteFrameFileList writeToFile:spriteSheetLookupFile atomically:YES];
}

- (void)generateFileLookup
{
    [_fileLookup writeToFileAtomically:[_outputDir stringByAppendingPathComponent:@"fileLookup.plist"]];
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

- (NSString *)description
{
    return [NSString stringWithFormat:@"target: %i, outputdir: %@, ", _targetType, _outputDir];
}

@end