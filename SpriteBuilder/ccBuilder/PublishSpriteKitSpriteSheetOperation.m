#import "PublishSpriteKitSpriteSheetOperation.h"
#import "AppDelegate.h"
#import "CCBWarnings.h"


@implementation PublishSpriteKitSpriteSheetOperation

- (void)main
{
    NSFileManager* fileManager = [NSFileManager defaultManager];

    // rename the resources-xxx folder for the atlas tool
    NSString* sourceDir = [_projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", _resolution]];
    NSString* sheetNameDir = [_projectSettings.tempSpriteSheetCacheDirectory stringByAppendingPathComponent:_spriteSheetName];
    [fileManager moveItemAtPath:sourceDir toPath:sheetNameDir error:nil];

    NSString* spriteSheetFile = [_spriteSheetDir stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", _resolution]];
    [fileManager createDirectoryAtPath:spriteSheetFile withIntermediateDirectories:YES attributes:nil error:nil];

    NSLog(@"Generating Sprite Kit Texture Atlas: %@", [NSString stringWithFormat:@"resources-%@/%@", _resolution, _spriteSheetName]);

    NSPipe* stdErrorPipe = [NSPipe pipe];
    [stdErrorPipe.fileHandleForReading readToEndOfFileInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(spriteKitTextureAtlasTaskCompleted:)
                                                 name:NSFileHandleReadToEndOfFileCompletionNotification
                                               object:stdErrorPipe.fileHandleForReading];

    // run task using Xcode TextureAtlas tool
    NSTask* atlasTask = [[NSTask alloc] init];
    atlasTask.launchPath = _textureAtlasToolLocation;
    atlasTask.arguments = @[sheetNameDir, spriteSheetFile];
    atlasTask.standardOutput = stdErrorPipe;
    [atlasTask launch];

    // Update progress
    [[AppDelegate appDelegate] modalStatusWindowUpdateStatusText:[NSString stringWithFormat:@"Generating sprite sheet %@...",
                                                                           [[_subPath stringByAppendingPathExtension:@"plist"] lastPathComponent]]];

    [atlasTask waitUntilExit];

    // rename back just in case
    [fileManager moveItemAtPath:sheetNameDir toPath:sourceDir error:nil];

    NSString* sheetPlist = [NSString stringWithFormat:@"resources-%@/%@.atlasc/%@.plist", _resolution, _spriteSheetName, _spriteSheetName];
    NSString* sheetPlistPath = [_spriteSheetDir stringByAppendingPathComponent:sheetPlist];
    if ([fileManager fileExistsAtPath:sheetPlistPath] == NO)
    {
        [_warnings addWarningWithDescription:@"TextureAtlas failed to generate! See preceding error message(s)."
                                     isFatal:YES
                                 relatedFile:_spriteSheetName
                                  resolution:_resolution];
    }

    // TODO: ?? because SK TextureAtlas tool itself checks if the spritesheet needs to be updated
    /*
     [CCBFileUtil setModificationDate:srcSpriteSheetDate forFile:[spriteSheetFile stringByAppendingPathExtension:@"plist"]];
     [publishedResources addObject:[subPath stringByAppendingPathExtension:@"plist"]];
     [publishedResources addObject:[subPath stringByAppendingPathExtension:@"png"]];
     */
}

- (void)cancel
{
    // TODO
    [super cancel];
}

-(void) spriteKitTextureAtlasTaskCompleted:(NSNotification *)notification
{
	// log additional warnings/errors from TextureAtlas tool
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:notification.object];

	NSData* data = [notification.userInfo objectForKey:NSFileHandleNotificationDataItem];
	NSString* errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (errorMessage.length)
	{
		NSLog(@"%@", errorMessage);
		[_warnings addWarningWithDescription:errorMessage isFatal:YES];
	}
}


@end