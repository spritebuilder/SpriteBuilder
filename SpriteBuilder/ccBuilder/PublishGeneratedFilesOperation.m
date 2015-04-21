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
    if (_projectSettings.designTarget == kSBDesignTargetFixed)
    {
        screenMode = @"CCScreenModeFixed";
    }
    else if (_projectSettings.designTarget == kSBDesignTargetFlexible)
    {
        screenMode = @"CCScreenModeFlexible";
    }

    configCocos2d[@"CCSetupScreenMode"] = screenMode;

    NSString *screenOrientation = @"";
    if (_projectSettings.defaultOrientation == kSBOrientationLandscape)
	{
		screenOrientation = @"CCScreenOrientationLandscape";
	}
	else if (_projectSettings.defaultOrientation == kSBOrientationPortrait)
	{
		screenOrientation = @"CCScreenOrientationPortrait";
	}

    configCocos2d[@"CCSetupScreenOrientation"] = screenOrientation;

    configCocos2d[@"CCSetupTabletScale2X"] = @YES;

    NSString *configCocos2dFile = [_outputDir stringByAppendingPathComponent:@"configCocos2d.plist"];
    [configCocos2d writeToFile:configCocos2dFile atomically:YES];
}

- (void)generateSpriteFrameFileList
{
    NSMutableDictionary*spriteFrameFileList = [NSMutableDictionary dictionary];

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    metadata[@"version"] = @1;

    spriteFrameFileList[@"metadata"] = metadata;
    spriteFrameFileList[@"spriteFrameFiles"] = [_publishedSpriteSheetFiles allObjects];

    NSString* spriteSheetLookupFile = [_outputDir stringByAppendingPathComponent:@"spriteFrameFileList.plist"];
    [spriteFrameFileList writeToFile:spriteSheetLookupFile atomically:YES];
}

- (void)generateFileLookup
{
    if (![_fileLookup writeToFileAtomically:[_outputDir stringByAppendingPathComponent:@"fileLookup.plist"]])
    {
        [_warnings addWarningWithDescription:@"Could not write fileLookup.plist."];
    }
    
    if (![_fileLookup TEMPwriteMetadataToFileAtomically:[_outputDir stringByAppendingPathComponent:@"metadata.plist"]])
    {
        [_warnings addWarningWithDescription:@"Could not write metadata.plist."];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"target: %i, outputdir: %@, ", _osType, _outputDir];
}

@end