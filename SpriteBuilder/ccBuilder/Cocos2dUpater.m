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
#import "Cocos2dUpater+Errors.h"

typedef enum
{
    Cocos2dVersionUpToDate = 0,
    Cocos2dVersionIncompatible,
} Cocos2dVersionComparisonResult;

typedef enum {
   UpdateActionUpdate = 0,
   UpdateActionNothingToDo,
   UpdateActionIgnoreVersion,
} UpdateActions;

static NSString *const REL_DEFAULT_COCOS2D_FOLDER_PATH = @"Source/libs/cocos2d-iphone/";


@implementation Cocos2dUpater
{
    NSString *_projectsCocos2dVersion;
    NSString *_sbCocos2dVersion;
    NSFileManager *_fileManager;
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
        _fileManager = [NSFileManager defaultManager];

        // TODO: remove me
        _sbCocos2dVersion = @"3.0.1";
    }

    return self;
}

- (void)update
{
    if ([self shouldIgnoreThisVersion])
    {
        NSLog(@"[COCO2D-UPDATER] Ignoring this version %@.", _sbCocos2dVersion);
        return;
    }

    if ([self isCoco2dAGitSubmodule])
    {
        NSLog(@"[COCO2D-UPDATER] cocos2d-iphone git submodule found, skipping.");
        return;
    }

    NSError *error;
    UpdateActions updateAction = [self determineUpdateAction:&error];

    if (updateAction == UpdateActionNothingToDo)
    {
        return;
    }

    if (updateAction == UpdateActionIgnoreVersion)
    {
        [self setIgnoreThisVersion];
        return;
    }

    [self doUpdate];
}

- (void)showErrorMessage:(NSError *)error
{
    NSAssert(error != nil, @"An error object is needed to show the error message.");

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Ok"];
    alert.messageText = @"Error updating Cocos2D";
    alert.informativeText = error.localizedDescription;
    [alert runModal];
}

- (void)rollBack
{
    // TODO: remove cocos2d folder if existent
    // TODO: rename backup folder to original name
}

- (void)doUpdate
{
    NSLog(@"[COCO2D-UPDATER] cocos2d-iphone VERSION file found, needs update, user opted for updating.");

    __block NSError *error;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^
    {
        [self updateModalDialogStatusText:@"Unzipping sources"];

        BOOL updateResult = [self unzipCocos2dFolder:&error]
            && [self renameCocos2dFolderToBackupPostfix:&error]
            && [self copySBsCocos2dFolderToProjectDir:&error]
            && [self tidyUpTempFolder:&error];

        [self finishWithUpdateStatus:updateResult error:error];
    });

    [_appDelegate modalStatusWindowStartWithTitle:@"Updating Cocos2D..."];
}

- (void)finishWithUpdateStatus:(BOOL)status error:(NSError *)error
{
    dispatch_sync(dispatch_get_main_queue(), ^
    {
        [_appDelegate modalStatusWindowFinish];

        if (status)
        {
            [self showUpdateInfoDialog];
        }
        else
        {
            [self showErrorMessage:error];
            [self rollBack];
        }
    });
}

- (void)updateModalDialogStatusText:(NSString *)text
{
    NSAssert(![NSThread isMainThread], @"Should only be called from non main queue.");
    dispatch_sync(dispatch_get_main_queue(), ^
    {
        [_appDelegate modalStatusWindowUpdateStatusText:text];
    });
}

- (UpdateActions)determineUpdateAction:(NSError **)error
{
    if ([self findAndCompareCocos2dVersionFile:error])
    {
        return [self showDialogToUpdateWithText:@"Project's Cocos2D version is outdated."];
    }
    else if ([self standardCocos2dFolderExists])
    {
        return [self showDialogToUpdateWithText:@"Cocos2D folder exists but no Version file could be found. This could mean your version is outdated."];
    }
    else
    {
        return UpdateActionNothingToDo;
    }
}

- (BOOL)findAndCompareCocos2dVersionFile:(NSError **)error
{
    return [self readProjectsCocos2dVersionFile:error]
        && ([self compareProjectsCocos2dVersionWithSBVersion] == Cocos2dVersionIncompatible);
}

- (void)setIgnoreThisVersion
{
    // TODO: add something to project file
}

- (BOOL)shouldIgnoreThisVersion
{
    // TODO: read project file
    return NO;
}

- (BOOL)unzipCocos2dFolder:(NSError **)error
{
    NSString *zipFile = [[NSBundle mainBundle] pathForResource:@"PROJECTNAME" ofType:@"zip" inDirectory:@"Generated"];
    NSString *tmpDir = [self tempFolderPathForUnzipping];

    if (![_fileManager fileExistsAtPath:zipFile])
    {
        *error = [self errorForNonExistentTemplateFile:zipFile];
        return NO;
    }

    if (![self tidyUpTempFolder:error])
    {
        return NO;
    }

    if (![_fileManager createDirectoryAtPath:tmpDir withIntermediateDirectories:NO attributes:nil error:error])
    {
        return NO;
    }

    return [self unzipZipFile:zipFile inTmpDir:tmpDir error:error];
}

- (BOOL)unzipZipFile:(NSString *)zipFile inTmpDir:(NSString *)tmpDir error:(NSError **)error
{
    NSTask *task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:tmpDir];
    [task setLaunchPath:@"/usr/bin/unzip"];
    NSArray *args = @[@"-d", tmpDir, @"-o", zipFile];
    [task setArguments:args];

    NSPipe *pipeStdOut = [NSPipe pipe];
    [task setStandardOutput:pipeStdOut];
    NSFileHandle *file = [pipeStdOut fileHandleForReading];
    NSData *dataStdOut;

    NSPipe *pipeStdErr = [NSPipe pipe];
    [task setStandardError:pipeStdErr];
    NSFileHandle *fileErr = [pipeStdErr fileHandleForReading];
    NSData *dataStdErr;

    int status = 0;
    @try
    {
        [task launch];

        // Not using waitUntilExit, see https://www.mikeash.com/pyblog/friday-qa-2009-11-13-dangerous-cocoa-calls.html
        while([task isRunning])
        {
            // Do this or the whole task may get locked, at least on my computer, without pipe for stdOut everything was
            // fine, some undrained buffer?
            dataStdOut = [file readDataToEndOfFile];
            dataStdErr = [fileErr readDataToEndOfFile];
        };
        status = [task terminationStatus];
    }
    @catch (NSException *exception)
    {
        *error = [self errorForUnzipTaskWithException:exception zipFile:zipFile];
        NSLog(@"[COCO2D-UPDATER] ERROR unzipping failed: %@", *error);
        return NO;
    }

    if (status)
    {
        *error = [self errorForFailedUnzipTask:zipFile dataStdOut:dataStdOut dataStdErr:dataStdErr status:status];
        NSLog(@"[COCO2D-UPDATER] ERROR unzipping failed: %@", *error);
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

    if ([_fileManager fileExistsAtPath:tmpDir]
        && ![_fileManager removeItemAtPath:tmpDir error:error])
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
        NSLog(@"[COCO2D-UPDATER] ERROR reading SB's cocos2d version file: %@", error);
    }

    return result;
}

- (BOOL)copySBsCocos2dFolderToProjectDir:(NSError **)error
{
    NSString *unzippedCocos2dFolder = [[self tempFolderPathForUnzipping] stringByAppendingPathComponent:REL_DEFAULT_COCOS2D_FOLDER_PATH];
    NSString *defaultCocos2DFolderPath = [self defaultCocos2DFolderPath];

    return [_fileManager copyItemAtPath:unzippedCocos2dFolder toPath:defaultCocos2DFolderPath error:error];
}

- (BOOL)renameCocos2dFolderToBackupPostfix:(NSError **)error
{
    NSString *defaultCocos2DFolderPath = [self defaultCocos2DFolderPath];
    NSString *cocos2dBackupName = [[defaultCocos2DFolderPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"cocos2d-iphone.backup"];

    return [_fileManager moveItemAtPath:defaultCocos2DFolderPath toPath:cocos2dBackupName error:error];
}

- (UpdateActions)showDialogToUpdateWithText:(NSString *)text
{
    NSMutableString *informativeText = [NSMutableString string];
    [informativeText appendString:text];
    [informativeText appendFormat:@"\nUpdate from version %@ to %@?", _projectsCocos2dVersion, _sbCocos2dVersion];
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
        case NSAlertFirstButtonReturn: return UpdateActionUpdate;
        case NSAlertSecondButtonReturn: return UpdateActionNothingToDo;
        case NSAlertThirdButtonReturn: return UpdateActionIgnoreVersion;
        default: return UpdateActionNothingToDo;
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

    if (![_fileManager fileExistsAtPath:gitmodulesPath])
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
    NSString *versionFilePath= [self defaultCocos2DFolderPath];
    versionFilePath = [versionFilePath stringByAppendingPathComponent:@"VERSION"];

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

- (NSString *)defaultCocos2DFolderPath
{
    NSString *rootDir = [_projectSettings.projectPath stringByDeletingLastPathComponent];
    return [rootDir stringByAppendingPathComponent:REL_DEFAULT_COCOS2D_FOLDER_PATH];
}

@end
