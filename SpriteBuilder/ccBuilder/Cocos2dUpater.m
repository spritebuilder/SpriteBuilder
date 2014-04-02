//
//  Cocos2dUpater.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 31.03.14.
//
//

#import "Cocos2dUpater.h"

#import "AppDelegate.h"
#import "ProjectSettings.h"
#import "NSString+RelativePath.h"
#import "SBErrors.h"

typedef enum
{
    Cocos2dVersionUpToDate = 0,
    Cocos2dVersionIncompatible,
} Cocos2dVersionComparisonResult;

typedef enum {
   UpdateDialogYes = 0,
    UpdateDialogNO,
    UpdateDialogIgnoreVersion,
} UpdateDialogAlternatives;

@implementation Cocos2dUpater
{
    NSString *_projectsCocos2dVersion;
    NSString *_sbCocos2dVersion;
}

- (instancetype)initWithAppDelegate:(AppDelegate *)appDelegate projectSettings:(ProjectSettings *)projectSettings
{
    self = [super init];
    if (self)
    {
        _appDelegate = appDelegate;
        _projectSettings = projectSettings;
        _projectsCocos2dVersion = nil;
        _sbCocos2dVersion = [self readSBCocos2dVersionFile];

        // TODO: revmove me
        _sbCocos2dVersion = @"3.0.1";
/*
        NSError *error;
        [self unzipCocos2dFolder:&error];
*/
    }

    return self;
}

- (void)update
{
    if ([self isCoco2dAGitSubmodule])
    {
        NSLog(@"[COCO2D-UPDATER] cocos2d-iphone submodule found, skipping.");
        return;
    }

    NSError *error;

    // Version file found
    if ([self readProjectsCocos2dVersionFile:&error]
        && ([self compareProjectsCocos2dVersionWithSBVersion] == Cocos2dVersionIncompatible)
        && [self showDialogToUpdateWithText:[self updateNeededDialogText]])
    {
        NSLog(@"[COCO2D-UPDATER] cocos2d-iphone VERSION file found, needs update, user opted for updating.");

        [self unzipCocos2dFolder:&error];

            [self renameCocos2dFolderToBackupPostfix];
            [self copySBsCocos2dFolderToProjectDir];
        [self tidyUpTempFolder:&error];
        [self showUpdateInfoDialog];
        return;
    }

    // no VERSION file found but folder exists
    if ([self standardCocos2dFolderExists]
        && [self showDialogToUpdateWithText:@"no Version file found..."])
    {
        // TODO: ignore action
        NSLog(@"[COCO2D-UPDATER] NO cocos2d-iphone VERSION file found, user opted for updating.");
        [self renameCocos2dFolderToBackupPostfix];
        [self copySBsCocos2dFolderToProjectDir];
        [self showUpdateInfoDialog];
        return;
    }
}

- (NSString *)updateNeededDialogText
{
    return [NSString stringWithFormat:@"Project's Cocos2D version(%@) is outdated, an update is needed. Update to version %@?", _projectsCocos2dVersion, _sbCocos2dVersion];
}

- (BOOL)unzipCocos2dFolder:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *zipFile = [[NSBundle mainBundle] pathForResource:@"PROJECTNAME" ofType:@"zip" inDirectory:@"Generated"];

    if (![fileManager fileExistsAtPath:zipFile])
    {
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:SBCocos2dUpdateTemplateZipFileDoesNotExistError
                                 userInfo:@{@"zipFile":zipFile,
                                         NSLocalizedDescriptionKey:@"Project template zip file does not exist, unable to extract newer cocos2d version."}];
        return NO;
    }

    if (![self tidyUpTempFolder:error])
    {
        return NO;
    }

    NSString *tmpDir = [self tempFolderPathForUnzipping];
    if (![fileManager createDirectoryAtPath:tmpDir withIntermediateDirectories:NO attributes:nil error:error])
    {
        return NO;
    }

    NSTask*task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:tmpDir];
    [task setLaunchPath:@"/usr/bin/unzip"];
    NSArray* args = @[@"-d", tmpDir, @"-o", zipFile];
    [task setArguments:args];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file = [pipe fileHandleForReading];
    [task setStandardInput:[NSPipe pipe]];
/*
    [task setStandardError:pipeErr];
*/

    int status = 0;

    @try
    {
        [task launch];
        [task waitUntilExit];
        status = [task terminationStatus];
    }
    @catch (NSException *exception)
    {
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:SBCocos2dUpdateUnzipTaskError
                                 userInfo:@{@"zipFile":zipFile,
                                         @"exception" : exception,
                                         NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Exception %@ thrown while running unzip task.", exception.name]}];

        NSLog(@"[COCO2D-UPDATER] unzipping failed: %@", *error);
        return NO;
    }

    if (status)
    {
        // TODO: add stdErr output
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:SBCocos2dUpdateUnzipTemplateFailedError
                                 userInfo:@{@"zipFile" : zipFile,
                                         NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unzip task exited with status code %d.", status]}];

        NSLog(@"[COCO2D-UPDATER] unzipping failed: %@", *error);
        return NO;
    }

    return YES;
}

- (NSString *)tempFolderPathForUnzipping
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.spritebuilder.updatecocos2d"];
}

- (BOOL)tidyUpTempFolder:(NSError **)error
{
    NSString *tmpDir = [self tempFolderPathForUnzipping];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ( ! [fileManager removeItemAtPath:tmpDir error:error])
    {
        NSLog(@"[COCO2D-UPDATER] Error tidying up unzip folder: %@", *error);
        return NO;
    }
    return YES;
}

- (void)showUpdateInfoDialog
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Cocos2D update"
                                      defaultButton:@"Ok"
                                    alternateButton:nil
                                        otherButton:nil
                          informativeTextWithFormat:@"Update finished."];
    [alert runModal];
}

- (NSString *)readSBCocos2dVersionFile
{
    NSString *versionFilePath = [[NSBundle mainBundle] pathForResource:@"cocos2d_version" ofType:@"txt" inDirectory:@"Generated"];

    NSError *error;
    NSString *result = [NSString stringWithContentsOfFile:versionFilePath encoding:NSUTF8StringEncoding error:&error];
    if (!result)
    {
        NSLog(@"[COCO2D-UPDATER] ERROR reading SB's cocos2d version: %@", error);
    }

    return result;
}

- (void)copySBsCocos2dFolderToProjectDir
{
    // TODO: implement me
}

- (void)renameCocos2dFolderToBackupPostfix
{
    // TODO: implement me
}

- (UpdateDialogAlternatives)showDialogToUpdateWithText:(NSString *)text
{
    // TODO: text param?
    NSMutableString *informativeText = [NSMutableString stringWithFormat:@"Update from version %@ to %@?", _projectsCocos2dVersion, _sbCocos2dVersion];
    [informativeText appendFormat:@"\nYour cocos2d source folder will be renamed with a \".backup\" postfix."];

    NSAlert *alert = [[NSAlert alloc] init];
    alert.informativeText = informativeText;
    alert.messageText = @"Cocos2D update";

    // beware: return value is depending on the position of the button
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert addButtonWithTitle:@"Ignore this version"];

    NSInteger returnValue = [alert runModal];
    switch (returnValue)
    {
        case NSAlertFirstButtonReturn: return UpdateDialogYes;
        case NSAlertSecondButtonReturn: return UpdateDialogNO;
        case NSAlertThirdButtonReturn: return UpdateDialogIgnoreVersion;
        default: return UpdateDialogNO;
    }
}

- (Cocos2dVersionComparisonResult)compareProjectsCocos2dVersionWithSBVersion
{
    NSLog(@"[COCO2D-UPDATER] Comparing version - SB: %@ with project: %@ ...", _sbCocos2dVersion, _projectsCocos2dVersion);

    return [_sbCocos2dVersion compare:_projectsCocos2dVersion options:NSNumericSearch] == NSOrderedDescending
        ? Cocos2dVersionIncompatible
        : Cocos2dVersionUpToDate;
}

- (BOOL)standardCocos2dFolderExists
{
    // TODO: implement me
    return NO;
}

- (BOOL)isCoco2dAGitSubmodule
{
    NSString *rootDir = [_projectSettings.projectPath stringByDeletingLastPathComponent];
    NSString *gitmodulesPath = [rootDir stringByAppendingPathComponent:@".gitmodules"];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:gitmodulesPath])
    {
        return NO;
    }

    NSError *error;
    NSString *submodulesContent = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:gitmodulesPath]
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error];

    NSRange cocos2dTextPosition = [submodulesContent rangeOfString:@"cocos2d-iphone.git" options:NSCaseInsensitiveSearch];

    return cocos2dTextPosition.location != NSNotFound;
}

- (BOOL)readProjectsCocos2dVersionFile:(NSError **)error
{
    NSString *rootDir = [_projectSettings.projectPath stringByDeletingLastPathComponent];
    NSString *versionFilePath = [rootDir stringByAppendingPathComponent:@"Source/libs/cocos2d-iphone/VERSION"];
    NSString *version = [NSString stringWithContentsOfFile:versionFilePath encoding:NSUTF8StringEncoding error:error];

    if (version)
    {
        _projectsCocos2dVersion = version;
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
