#import "PublishGeneratedFilesOperation.h"

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

    [self generateFileLookup];

    [self generateSpriteFrameFileList];

    [self generateCocos2dSetupFile];
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
    if (![_fileLookup writeToFileAtomically:[_outputDir stringByAppendingPathComponent:@"fileLookup.plist"]])
    {
        [_warnings addWarningWithDescription:@"Could not write fileLookup.plist."];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"target: %i, outputdir: %@, ", _osType, _outputDir];
}

@end