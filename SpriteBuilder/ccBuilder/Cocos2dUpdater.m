//
//  Cocos2dUpdater.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 31.03.14.
//
//

#import "Cocos2dUpdater.h"

#import "AppDelegate.h"
#import "ProjectSettings.h"
#import "Cocos2dUpdater+Errors.h"


// Debug option: Some verbosity on the console, 1 to enable 0 to turn off
#define Cocos2UpdateLogging 0

#ifdef DEBUG
	#define LocalLog( s, ... ) NSLog( @"<%@:%d> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
	#define LocalLog( s, ... )
#endif

#if !Cocos2UpdateLogging
    #undef LocalLog
    #define LocalLog( s, ... )
#endif


typedef enum
{
    Cocos2dVersionUpToDate = 0,
    Cocos2dVersionIncompatible,
    Cocos2dVersionProjectVersionUnknown,
} Cocos2dVersionComparisonResult;

typedef enum {
   UpdateActionUpdate = 0,
   UpdateActionNothingToDo,
   UpdateActionIgnoreVersion,
} UpdateActions;

static NSString *const REL_DEFAULT_COCOS2D_FOLDER_PATH = @"Source/libs/cocos2d-iphone/";
static NSString *const BASE_COCOS2D_BACKUP_NAME = @"cocos2d-iphone.backup";

@implementation Cocos2dUpdater
{
    NSString *_projectsCocos2dVersion;
    NSString *_spritebuildersCocos2dVersion;
    NSString *_backupFolderPath;
    NSFileManager *_fileManager;
}

- (instancetype)init
{
    NSLog(@"Use initWithAppDelegate:projectSettings: to create instances");
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithAppDelegate:(AppDelegate *)appDelegate projectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"Project settings needed to instantiate the updater.");

    self = [super init];
    if (self)
    {
        _appDelegate = appDelegate;
        _projectSettings = projectSettings;

        _spritebuildersCocos2dVersion = [self readSpriteBuildersCocos2dVersionFile];
        _projectsCocos2dVersion = [self readProjectsCocos2dVersionFile];
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (void)updateAndBypassIgnore:(BOOL)bypassIgnore
{
    [self updateProjectSettingsIfUserCanUpdate];

    if ([self shouldIgnoreThisVersion] && !bypassIgnore)
    {
        LocalLog(@"[COCO2D-UPDATER] [INFO] Ignoring this version %@.", _spritebuildersCocos2dVersion);
        return;
    }

    if ([self isCoco2dAGitSubmodule])
    {
        LocalLog(@"[COCO2D-UPDATER] [INFO] cocos2d-iphone git submodule found, skipping.");
        return;
    }

    [self setBackupFolderPath];
    UpdateActions updateAction = [self updateAction];

    if (updateAction == UpdateActionNothingToDo)
    {
        return;
    }

    if (updateAction == UpdateActionIgnoreVersion)
    {
        LocalLog(@"[COCO2D-UPDATER] [INFO] Now ignoring this version %@.", _spritebuildersCocos2dVersion);
        [self setIgnoreThisVersion];
        return;
    }

    [self doUpdate];
}

- (void)updateProjectSettingsIfUserCanUpdate
{
    Cocos2dVersionComparisonResult compareResult = [self compareProjectsCocos2dVersionWithSpriteBuildersVersion];

   _projectSettings.canUpdateCocos2D = ![self isCoco2dAGitSubmodule]
               && ((compareResult == Cocos2dVersionIncompatible)
               || [self doesProjectsCocos2dFolderExistAndHasNoVesionfile]);;
}

- (BOOL)doesProjectsCocos2dFolderExistAndHasNoVesionfile
{
    Cocos2dVersionComparisonResult compareResult = [self compareProjectsCocos2dVersionWithSpriteBuildersVersion];

    return compareResult == Cocos2dVersionProjectVersionUnknown
                 && [self defaultProjectsCocos2dFolderExists];
}

- (UpdateActions)updateAction
{
    Cocos2dVersionComparisonResult compareResult = [self compareProjectsCocos2dVersionWithSpriteBuildersVersion];

    if (compareResult == Cocos2dVersionUpToDate)
    {
        return UpdateActionNothingToDo;
    }
    else if (compareResult == Cocos2dVersionIncompatible)
    {
        return [self showUpdateDialogWithText:@"Your project is not using the latest version of Cocos2D. It's recommended that you update."];
    }
    else if ([self doesProjectsCocos2dFolderExistAndHasNoVesionfile])
    {
        return [self showUpdateDialogWithText:@"Your project is probably not using the latest version of Cocos2D (the version file is missing, which indicates that you are using an old version). It's recommended that you update."];
    }
    else
    {
        return UpdateActionNothingToDo;
    }
}

- (void)doUpdate
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] updating...");

    __block NSError *error;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^
    {
        [self updateModalDialogStatusText:@"Unzipping sources"];

        BOOL updateResult = [self unzipProjectTemplateZip:&error]
            && [self renameCocos2dFolderToBackupFolder:&error]
            && [self copySpriteBuildersCocos2dFolderToProjectFolder:&error]
            && [self tidyUpTempFolder:&error];

        [self finishWithUpdateResult:updateResult error:error];
    });

    [_appDelegate modalStatusWindowStartWithTitle:@"Updating Cocos2D..."];
}

- (void)setBackupFolderPath
{
    _backupFolderPath = [self cocos2dBackupFolderPath:[self defaultProjectsCocos2DFolderPath]];
}

- (void)finishWithUpdateResult:(BOOL)status error:(NSError *)error
{
    dispatch_sync(dispatch_get_main_queue(), ^
    {
        [_appDelegate modalStatusWindowFinish];

        if (status)
        {
            LocalLog(@"[COCO2D-UPDATER] [INFO] Success!");
            _projectSettings.canUpdateCocos2D = NO;
            [_projectSettings.cocos2dUpdateIgnoredVersions removeObject:_spritebuildersCocos2dVersion];
            [self openBrowserWithCocos2dUpdateInformation];
            [self showUpdateSuccessDialog];
        }
        else
        {
            LocalLog(@"[COCO2D-UPDATER] [INFO] Updating failed! Rolling back...");
            [self showUpdateErrorDialog:error];
            [self rollBack];
        }
    });
}

- (void)openBrowserWithCocos2dUpdateInformation
{
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    [workspace openURL:[NSURL URLWithString:@"http://www.spritebuilder.com/update/"]];
}

- (void)showUpdateErrorDialog:(NSError *)error
{
    NSAssert(error != nil, @"An error object is needed to show the error message.");

    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Ok"];
    alert.messageText = @"Error updating Cocos2D";
    alert.informativeText = [NSString stringWithFormat:@"An error occured while updating. Rolling back. \nError: %@\n\nBackup folder restored.", error.localizedDescription];
    [alert runModal];
}

- (void)rollBack
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] Rolling back.");

    NSString *defaultCocos2DFolderPath = [self defaultProjectsCocos2DFolderPath];

    // Without the backup folder we can't say what went wrong but
    // it is safe to not do anything
    if (![_fileManager fileExistsAtPath:_backupFolderPath])
    {
        return;
    }

    if ([_fileManager fileExistsAtPath:defaultCocos2DFolderPath])
    {
        [_fileManager removeItemAtPath:defaultCocos2DFolderPath error:nil];
    }

    [_fileManager moveItemAtPath:_backupFolderPath toPath:defaultCocos2DFolderPath error:nil];
}

- (void)updateModalDialogStatusText:(NSString *)text
{
    NSAssert(![NSThread isMainThread], @"Should only be called from non main queue.");
    dispatch_sync(dispatch_get_main_queue(), ^
    {
        [_appDelegate modalStatusWindowUpdateStatusText:text];
    });
}

- (void)setIgnoreThisVersion
{
	// SI: added check for _spritebuildersCocos2dVersion being nil - happens if you click "Ignore this version" (at least in dev builds)
    if (_spritebuildersCocos2dVersion && ![_projectSettings.cocos2dUpdateIgnoredVersions containsObject:_spritebuildersCocos2dVersion])
    {
        [_projectSettings.cocos2dUpdateIgnoredVersions addObject:_spritebuildersCocos2dVersion];
    }
}

- (BOOL)shouldIgnoreThisVersion
{
    return [_projectSettings.cocos2dUpdateIgnoredVersions containsObject:_spritebuildersCocos2dVersion];
}

- (BOOL)unzipProjectTemplateZip:(NSError **)error
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
        NSLog(@"[COCO2D-UPDATER] [ERROR] unzipping failed: %@", *error);
        return NO;
    }

    if (status)
    {
        *error = [self errorForFailedUnzipTask:zipFile dataStdOut:dataStdOut dataStdErr:dataStdErr status:status];
        NSLog(@"[COCO2D-UPDATER] [ERROR] unzipping failed: %@", *error);
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
        LocalLog(@"[COCO2D-UPDATER] [ERROR] tidying up unzip folder: %@", *error);
        return NO;
    }
    return YES;
}

- (void)showUpdateSuccessDialog
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.informativeText = @"Your project has been updated to use the latest version of Cocos2D.\n\nPlease test your Xcode project. If you encounter any issues check spritebuilder.com for more information.";
    [alert addButtonWithTitle:@"OK"];
    alert.messageText = @"Cocos2D Update Complete";
    [alert runModal];
}

- (NSString *)readSpriteBuildersCocos2dVersionFile
{
    NSString *versionFilePath = [[NSBundle mainBundle] pathForResource:@"cocos2d_version" ofType:@"txt" inDirectory:@"Generated"];

    NSError *error;
    NSString *result = [NSString stringWithContentsOfFile:versionFilePath encoding:NSUTF8StringEncoding error:&error];
    if (!result)
    {
        LocalLog(@"[COCO2D-UPDATER] [ERROR] reading SB's cocos2d version file: %@", error);
    }

    LocalLog(@"[COCO2D-UPDATER] [INFO] SpriteBuilder's cocos2d version: %@", result);

    return result;
}

- (BOOL)copySpriteBuildersCocos2dFolderToProjectFolder:(NSError **)error
{
    NSString *unzippedCocos2dFolder = [[self tempFolderPathForUnzipping] stringByAppendingPathComponent:REL_DEFAULT_COCOS2D_FOLDER_PATH];

    return [_fileManager copyItemAtPath:unzippedCocos2dFolder
                                 toPath:[self defaultProjectsCocos2DFolderPath] error:error];
}

- (BOOL)renameCocos2dFolderToBackupFolder:(NSError **)error
{
    return [_fileManager moveItemAtPath:[self defaultProjectsCocos2DFolderPath]
                                 toPath:_backupFolderPath error:error];
}

- (NSString *)cocos2dBackupFolderPath:(NSString *)defaultCocos2DFolderPath
{
    NSString *result = [[defaultCocos2DFolderPath stringByDeletingLastPathComponent]
                                                  stringByAppendingPathComponent:BASE_COCOS2D_BACKUP_NAME];

    if ([_fileManager fileExistsAtPath:result])
    {
        return [self cocos2dBackupFolderNameWithCounterPostfix:defaultCocos2DFolderPath cocos2dBackupFolderPath:result];
    }
    return result;
}

- (NSString *)cocos2dBackupFolderNameWithCounterPostfix:(NSString *)defaultCocos2DFolderPath cocos2dBackupFolderPath:(NSString *)cocos2dBackupName
{
    NSUInteger maxCounter = 0;

    NSString *libsFolder = [defaultCocos2DFolderPath stringByAppendingPathComponent:@".."];
    NSArray *dirContents = [_fileManager contentsOfDirectoryAtPath:libsFolder error:nil];

    for (NSString *directoryName in dirContents)
    {
        maxCounter = [self highestBackupDirCounterPostfix:cocos2dBackupName currentCount:maxCounter directoryName:directoryName];
    }
    return [cocos2dBackupName stringByAppendingString:[NSString stringWithFormat:@".%lu", maxCounter]];
}

- (NSUInteger)highestBackupDirCounterPostfix:(NSString *)cocos2dBackupName currentCount:(NSUInteger)currentCounter directoryName:(NSString *)directoryName
{
    NSNumber *number = [self parseNumberPostfixInBackupDir:directoryName];

    if (number
        && ([number unsignedIntegerValue] > currentCounter))
    {
        currentCounter = [number unsignedIntegerValue] + 1;
    }

    return currentCounter;
}

- (NSNumber *)parseNumberPostfixInBackupDir:(NSString *)directoryName
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSString *pattern = [NSString stringWithFormat:@"%@.", BASE_COCOS2D_BACKUP_NAME];
    NSString *counterOnlyString = [directoryName stringByReplacingOccurrencesOfString:pattern withString:@""];
    return [numberFormatter numberFromString:counterOnlyString];
}

- (UpdateActions)showUpdateDialogWithText:(NSString *)text
{
    NSMutableString *informativeText = [NSMutableString string];
    [informativeText appendString:text];
    [informativeText appendFormat:@"\n\nBefore updating we will make a backup of your old Cocos2D folder and rename it to \"%@\".", [_backupFolderPath lastPathComponent]];

    if (_projectsCocos2dVersion)
    {
        [informativeText appendFormat:@"\n\nUpdate from version %@ to %@?", _projectsCocos2dVersion, _spritebuildersCocos2dVersion];
    }
    else
    {
        [informativeText appendFormat:@"\n\nUpdate to version %@?", _spritebuildersCocos2dVersion];
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.informativeText = informativeText;
    alert.messageText = @"Cocos2D Automatic Updater";

    // beware: return value is depending on the position of the button
    [alert addButtonWithTitle:@"Update"];
    [alert addButtonWithTitle:@"Cancel"];
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

- (Cocos2dVersionComparisonResult)compareProjectsCocos2dVersionWithSpriteBuildersVersion
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] Comparing version - SB: %@ with project: %@ ...", _spritebuildersCocos2dVersion, _projectsCocos2dVersion);

    if (!_projectsCocos2dVersion)
    {
        return Cocos2dVersionProjectVersionUnknown;
    }

    NSComparisonResult result = [_spritebuildersCocos2dVersion compare:_projectsCocos2dVersion options:NSNumericSearch];

    return result == NSOrderedAscending || result == NSOrderedSame
        ? Cocos2dVersionUpToDate
        : Cocos2dVersionIncompatible;
}

- (BOOL)defaultProjectsCocos2dFolderExists
{
    return [_fileManager fileExistsAtPath:[self defaultProjectsCocos2DFolderPath]];
}

- (BOOL)isCoco2dAGitSubmodule
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] Testing if there's a .gitmodules file ...");

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
    BOOL result = cocos2dTextPosition.location != NSNotFound;

    LocalLog(@"[COCO2D-UPDATER] [INFO] .gitmodules file found, contains cocos2d-iphone.git? %d", result);

    return result;
}

- (NSString *)readProjectsCocos2dVersionFile
{
    NSString *versionFilePath = [self defaultProjectsCocos2DFolderPath];
    versionFilePath = [versionFilePath stringByAppendingPathComponent:@"VERSION"];

    __block NSString *version;
    NSString *fileContent = [NSString stringWithContentsOfFile:versionFilePath encoding:NSUTF8StringEncoding error:nil];
    [fileContent enumerateLinesUsingBlock:^(NSString *line, BOOL *stop)
    {
        version = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        *stop = YES;
    }];

    if (version)
    {
        LocalLog(@"[COCO2D-UPDATER] [INFO] Version file found in Project: %@", fileContent);
        return version;
    }
    return nil;
}

- (NSString *)defaultProjectsCocos2DFolderPath
{
    NSString *rootDir = [_projectSettings.projectPath stringByDeletingLastPathComponent];
    return [rootDir stringByAppendingPathComponent:REL_DEFAULT_COCOS2D_FOLDER_PATH];
}

@end