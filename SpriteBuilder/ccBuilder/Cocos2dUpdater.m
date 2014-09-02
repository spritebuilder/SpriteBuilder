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
#import "copyfile.h"
#import "SBErrors.h"
#import "NSError+SBErrors.h"
#import "NSAlert+Convenience.h"
#import "SemanticVersioning.h"

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
static NSString *const URL_COCOS2D_UPDATE_INFORMATION = @"http://www.spritebuilder.com/update/";


@interface Cocos2dUpdater ()

@property (nonatomic, weak, readwrite) AppDelegate *appDelegate;
@property (nonatomic, weak, readwrite) ProjectSettings *projectSettings;

@property (nonatomic, strong) NSTask *task;
@property (nonatomic, strong) NSFileHandle *outFile;
@property (nonatomic, getter=isCancelled) BOOL cancelled;
@property (nonatomic, copy) NSString *projectsCocos2dVersion;
@property (nonatomic, copy) NSString *spritebuildersCocos2dVersion;
@property (nonatomic, copy) NSString *backupFolderPath;

@end


@implementation Cocos2dUpdater

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
        self.appDelegate = appDelegate;
        self.projectSettings = projectSettings;

        self.spritebuildersCocos2dVersion = [self readSpriteBuildersCocos2dVersionFile];
        self.projectsCocos2dVersion = [self readProjectsCocos2dVersionFile];
    }
    return self;
}

- (void)updateAndBypassIgnore:(BOOL)bypassIgnore
{
    NSAssert(_projectSettings != nil, @"Project settings needed to instantiate the updater.");

    [self updateProjectSettingsIfUserCanUpdate];

    if ([self shouldIgnoreThisVersion] && !bypassIgnore)
    {
        LocalLog(@"[COCO2D-UPDATER] [INFO] Ignoring this version %@.", self.spritebuildersCocos2dVersion);
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
        LocalLog(@"[COCO2D-UPDATER] [INFO] Now ignoring this version %@.", self.spritebuildersCocos2dVersion);
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


    __weak id weakSelf = self;
    [_appDelegate modalStatusWindowStartWithTitle:@"Updating Cocos2D..." isIndeterminate:YES onCancelBlock:^
    {
        [weakSelf cancel];
    }];
}

- (void)setBackupFolderPath
{
    self.backupFolderPath = [self cocos2dBackupFolderPath:[self defaultProjectsCocos2DFolderPath]];
}

- (void)finishWithUpdateResult:(BOOL)status error:(NSError *)error
{
    [self runOnMainThread:^
    {
        [_appDelegate modalStatusWindowFinish];

        if (status)
        {
            LocalLog(@"[COCO2D-UPDATER] [INFO] Success!");
            _projectSettings.canUpdateCocos2D = NO;
            [_projectSettings.cocos2dUpdateIgnoredVersions removeObject:self.spritebuildersCocos2dVersion];
            [self openBrowserWithCocos2dUpdateInformation];
            [self showUpdateSuccessDialog];
        }
        else
        {
            LocalLog(@"[COCO2D-UPDATER] [INFO] Updating failed! Rolling back...");
            [self showUpdateErrorDialog:error];
            [self rollBack];
        }

    }];
}

- (void)runOnMainThread:(dispatch_block_t)block
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
		
		CFRunLoopPerformBlock(([[NSRunLoop mainRunLoop] getCFRunLoop]), (__bridge CFStringRef)NSModalPanelRunLoopMode, ^{
            block();
        });
    }
}

- (void)openBrowserWithCocos2dUpdateInformation
{
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    [workspace openURL:[NSURL URLWithString:URL_COCOS2D_UPDATE_INFORMATION]];
}

- (void)showUpdateErrorDialog:(NSError *)error
{
    if (!self.isCancelled)
    {
        [NSAlert showModalDialogWithTitle:@"Error updating Cocos2D"
                                  message:[NSString stringWithFormat:@"An error occured while updating. Rolling back. \nError: %@\n\nBackup folder restored.", error.localizedDescription]];
    }
}

- (void)rollBack
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] Rolling back.");
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *defaultCocos2DFolderPath = [self defaultProjectsCocos2DFolderPath];

    // Without the backup folder we can't say what went wrong but
    // it is safe to not do anything
    if (![fileManager fileExistsAtPath:self.backupFolderPath])
    {
        return;
    }

    if ([fileManager fileExistsAtPath:defaultCocos2DFolderPath])
    {
        [fileManager removeItemAtPath:defaultCocos2DFolderPath error:nil];
    }

    [fileManager moveItemAtPath:self.backupFolderPath toPath:defaultCocos2DFolderPath error:nil];
}

- (void)updateModalDialogStatusText:(NSString *)text
{
    [self runOnMainThread:^
    {
        [_appDelegate modalStatusWindowUpdateStatusText:text];
    }];
}

- (void)setIgnoreThisVersion
{
	// SI: added check for _spritebuildersCocos2dVersion being nil - happens if you click "Ignore this version" (at least in dev builds)
    if (self.spritebuildersCocos2dVersion
        && ![_projectSettings.cocos2dUpdateIgnoredVersions containsObject:self.spritebuildersCocos2dVersion])
    {
        [_projectSettings.cocos2dUpdateIgnoredVersions addObject:self.spritebuildersCocos2dVersion];
    }
}

- (BOOL)shouldIgnoreThisVersion
{
    return [_projectSettings.cocos2dUpdateIgnoredVersions containsObject:self.spritebuildersCocos2dVersion];
}

- (BOOL)unzipProjectTemplateZip:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *zipFile = [[NSBundle mainBundle] pathForResource:@"PROJECTNAME" ofType:@"zip" inDirectory:@"Generated"];
    NSString *tmpDir = [self tempFolderPathForUnzipping];

    if (![fileManager fileExistsAtPath:zipFile])
    {
        LocalLog(@"[COCO2D-UPDATER] [ERROR] template file does not exist at path \"%@\"", zipFile);
        *error = [self errorForNonExistentTemplateFile:zipFile];
        return NO;
    }

    LocalLog(@"[COCO2D-UPDATER] [INFO] cleaning temp folder just in case before update does anything");
    if (![self tidyUpTempFolder:error])
    {
        return NO;
    }

    if (![fileManager createDirectoryAtPath:tmpDir withIntermediateDirectories:NO attributes:nil error:error])
    {
        LocalLog(@"[COCO2D-UPDATER] [ERROR] could not create directory at path \"%@\" with error %@", tmpDir, error);
        return NO;
    }

    return [self unzipZipFile:zipFile inTmpDir:tmpDir error:error];
}

- (BOOL)unzipZipFile:(NSString *)zipFile inTmpDir:(NSString *)tmpDir error:(NSError **)error
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] unzipping template project archive to temp folder \"%@\"", tmpDir);

    self.task = [[NSTask alloc] init];
    [_task setCurrentDirectoryPath:tmpDir];
    [_task setLaunchPath:@"/usr/bin/unzip"];

    NSArray *args = @[@"-d", tmpDir, @"-o", zipFile];
    [_task setArguments:args];

    NSPipe *pipeStdOut = [NSPipe pipe];
    [_task setStandardOutput:pipeStdOut];
    self.outFile = [pipeStdOut fileHandleForReading];
    [_outFile waitForDataInBackgroundAndNotify];    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataAvailaCallback:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:nil];

    int status = 0;
    @try
    {
        [_task launch];
        [_task waitUntilExit];

        status = [_task terminationStatus];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    @catch (NSException *exception)
    {
        *error = [self errorForUnzipTaskWithException:exception zipFile:zipFile];
        NSLog(@"[COCO2D-UPDATER] [ERROR] unzipping failed: %@", *error);
        return NO;
    }

    if (status)
    {
        *error = [self errorForFailedUnzipTaskWithstatus:status];
        NSLog(@"[COCO2D-UPDATER] [ERROR] unzipping failed: %@", *error);
        return NO;
    }

    return YES;
}

- (void)dataAvailaCallback:(NSNotification *)notification
{
    NSFileHandle *fileHandle = notification.object;

    NSData *data = nil;
    while ((data = [fileHandle availableData]) && [data length])
    {
        NSString *output = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
        [self updateProgressOfCurrentUnzippedFilePath:output];
    }
}

- (void)updateProgressOfCurrentUnzippedFilePath:(NSString *)output
{
    NSRange tempPathRange = [output rangeOfString:[[self tempFolderPathForUnzipping] stringByAppendingString:@"/"]];
    if (tempPathRange.location != NSNotFound)
    {
        NSString *shortenedFilePath = [output stringByReplacingCharactersInRange:NSMakeRange(0, tempPathRange.location + tempPathRange.length)                                              withString:@""];
        [self updateModalDialogStatusText:[NSString stringWithFormat:@"Unzipping: %@", shortenedFilePath]];
    }
}

- (NSString *)tempFolderPathForUnzipping
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.spritebuilder.updatecocos2d"];
}

- (BOOL)tidyUpTempFolder:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];;

    NSString *tmpDir = [self tempFolderPathForUnzipping];
    LocalLog(@"[COCO2D-UPDATER] [INFO] tidying up temp folder: %@", tmpDir);

    [self updateModalDialogStatusText:@"Tidying up..."];

    if ([fileManager fileExistsAtPath:tmpDir]
        && ![fileManager removeItemAtPath:tmpDir error:error])
    {
        LocalLog(@"[COCO2D-UPDATER] [ERROR] tidying up unzip folder: %@", *error);
        return NO;
    }
    return YES;
}

- (void)showUpdateSuccessDialog
{
    [NSAlert showModalDialogWithTitle:@"Cocos2D Update Complete"
                              message:@"Your project has been updated to use the latest version of Cocos2D.\n\nPlease test your Xcode project. If you encounter any issues check spritebuilder.com for more information."];
}

- (NSString *)readSpriteBuildersCocos2dVersionFile
{
    NSString *versionFilePath = [[NSBundle mainBundle] pathForResource:@"cocos2d_version" ofType:@"txt" inDirectory:@"Generated"];

    if (versionFilePath == nil)
    {
        LocalLog(@"[COCO2D-UPDATER] [ERROR] Generated/cocos2d_version.txt could not be found! Version cannot be determined. If developing, rerun scripts/BuildDistribution.sh and try again.");
        return nil;
    }

    NSError *error;
    NSString *result = [NSString stringWithContentsOfFile:versionFilePath encoding:NSUTF8StringEncoding error:&error];
    if (!result)
    {
        LocalLog(@"[COCO2D-UPDATER] [ERROR] reading SB's cocos2d version file: %@", error);
    }

    LocalLog(@"[COCO2D-UPDATER] [INFO] SpriteBuilder's cocos2d version: %@", result);

    return result;
}

static int copyFileCallback(int currentState, int stage, copyfile_state_t state, const char *fromPath, const char *toPath, void *context)
{
    Cocos2dUpdater *self = (__bridge Cocos2dUpdater *) context;
    if (self.isCancelled)
    {
        return COPYFILE_QUIT;
    }

    if (currentState == COPYFILE_COPY_DATA
        && stage == COPYFILE_PROGRESS)
    {
        off_t copiedBytes;
        const int returnCode = copyfile_state_get(state, COPYFILE_STATE_COPIED, &copiedBytes);
        if (returnCode == 0)
        {
            NSString *text = [NSString stringWithFormat:@"Copying: %s (%@)", fromPath, [NSByteCountFormatter stringFromByteCount:copiedBytes countStyle:NSByteCountFormatterCountStyleFile]];
            [self updateModalDialogStatusText:text];
            // NSLog(@"%@", text);
        }
    }
    else
    {
        NSString *text = [NSString stringWithFormat:@"Copying: %@", [NSString stringWithCString:toPath encoding:NSUTF8StringEncoding]] ;
        [self updateModalDialogStatusText:text];
        // NSLog(@"%@", text);
    }

    return COPYFILE_CONTINUE;
}

- (BOOL)copySpriteBuildersCocos2dFolderToProjectFolder:(NSError **)error
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] copying unzipped cocos2d folder from temp to project");
    [self updateModalDialogStatusText:@"Copying files..."];

    NSString *unzippedCocos2dFolder = [[self tempFolderPathForUnzipping] stringByAppendingPathComponent:REL_DEFAULT_COCOS2D_FOLDER_PATH];

    const char *fromPath = [unzippedCocos2dFolder fileSystemRepresentation];
    const char *toPath = [[self defaultProjectsCocos2DFolderPath] fileSystemRepresentation];

    copyfile_state_t copyfileState = copyfile_state_alloc();
    copyfile_state_set(copyfileState, COPYFILE_STATE_STATUS_CB, &copyFileCallback);
    copyfile_state_set(copyfileState, COPYFILE_STATE_STATUS_CTX, (__bridge void *)self);

    int result = copyfile(fromPath, toPath, copyfileState, COPYFILE_ALL | COPYFILE_RECURSIVE);

    copyfile_state_free(copyfileState);

    if (result)
    {
        if (!self.isCancelled)
        {
            [NSError setNewErrorWithCode:error
                                    code:SBCocos2dUpdateCopyFilesError
                                 message:@"An error occured copying the cocos2d folder to the project directory."];

            LocalLog(@"[COCO2D-UPDATER] [ERROR] could not copy cocos2d folder from \"%@\" to \"%@\" with error %@",
                     unzippedCocos2dFolder, [self defaultProjectsCocos2DFolderPath], *error);
        }
        else
        {
            [NSError setNewErrorWithCode:error
                                    code:SBCocos2dUpdateUserCancelledError
                                 message:@"Update cancelled."];
        }
    }

    return result == 0;
}

- (BOOL)renameCocos2dFolderToBackupFolder:(NSError **)error
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] renaming project's cocos2d folder to backup name \"%@\"", self.backupFolderPath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager moveItemAtPath:[self defaultProjectsCocos2DFolderPath]
                                            toPath:self.backupFolderPath
                                             error:error];
    if (!result)
    {
        LocalLog(@"[COCO2D-UPDATER] [ERROR] could not renamed cocos2d folder to backup folder name: from \"%@\" to \"%@\" with error %@",
                 [self defaultProjectsCocos2DFolderPath], self.backupFolderPath, *error);
    }
    return result;
}

- (NSString *)cocos2dBackupFolderPath:(NSString *)defaultCocos2DFolderPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *result = [[defaultCocos2DFolderPath stringByDeletingLastPathComponent]
                                                  stringByAppendingPathComponent:BASE_COCOS2D_BACKUP_NAME];

    if ([fileManager fileExistsAtPath:result])
    {
        return [self cocos2dBackupFolderNameWithCounterPostfix:defaultCocos2DFolderPath cocos2dBackupFolderPath:result];
    }
    return result;
}

- (NSString *)cocos2dBackupFolderNameWithCounterPostfix:(NSString *)defaultCocos2DFolderPath cocos2dBackupFolderPath:(NSString *)cocos2dBackupName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSUInteger maxCounter = 0;

    NSString *libsFolder = [defaultCocos2DFolderPath stringByAppendingPathComponent:@".."];
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:libsFolder error:nil];

    for (NSString *directoryName in dirContents)
    {
        maxCounter = [self highestBackupDirCounterPostfixCurrentCount:maxCounter directoryName:directoryName];
    }
    return [cocos2dBackupName stringByAppendingString:[NSString stringWithFormat:@".%lu", maxCounter]];
}

- (NSUInteger)highestBackupDirCounterPostfixCurrentCount:(NSUInteger)currentCounter directoryName:(NSString *)directoryName
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
    [informativeText appendFormat:@"\n\nBefore updating we will make a backup of your old Cocos2D folder and rename it to \"%@\".", [self.backupFolderPath lastPathComponent]];

    if (self.projectsCocos2dVersion)
    {
        [informativeText appendFormat:@"\n\nUpdate from version %@ to %@?", self.projectsCocos2dVersion, self.spritebuildersCocos2dVersion];
    }
    else
    {
        [informativeText appendFormat:@"\n\nUpdate to version %@?", self.spritebuildersCocos2dVersion];
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
    LocalLog(@"[COCO2D-UPDATER] [INFO] Comparing version - SB: %@ with project: %@ ...", self.spritebuildersCocos2dVersion, self.projectsCocos2dVersion);

    if (!self.projectsCocos2dVersion)
    {
        return Cocos2dVersionProjectVersionUnknown;
    }
	
	SemanticVersioning * sbVersion = [[SemanticVersioning alloc] initWithString:self.spritebuildersCocos2dVersion];
	SemanticVersioning * projectVersion = [[SemanticVersioning alloc] initWithString:self.projectsCocos2dVersion];
	
	NSComparisonResult result = [sbVersion compare:projectVersion];

    return result == NSOrderedAscending || result == NSOrderedSame
        ? Cocos2dVersionUpToDate
        : Cocos2dVersionIncompatible;
}

- (BOOL)defaultProjectsCocos2dFolderExists
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[self defaultProjectsCocos2DFolderPath]];
}

- (BOOL)isCoco2dAGitSubmodule
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] Testing if there's a .gitmodules file ...");

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

- (void)cancel
{
    LocalLog(@"[COCO2D-UPDATER] [INFO] USER CANCELLED UPDATE");
    [_task terminate];
    self.cancelled = YES;
}

- (NSError *)errorForFailedUnzipTaskWithstatus:(int)status
{
    NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Unzip task exited with status code %d. See console app.", status]
    };

    return [NSError errorWithDomain:SBErrorDomain
                               code:SBCocos2dUpdateUnzipTemplateFailedError
                           userInfo:userInfo];
}

- (NSError *)errorForUnzipTaskWithException:(NSException *)exception zipFile:(NSString *)zipFile
{
    NSDictionary *userInfo = @{
            @"zipFile" : zipFile,
            @"exception" : exception,
            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Exception %@ thrown while running unzip task.", exception.name]};

    return [NSError errorWithDomain:SBErrorDomain
                                     code:SBCocos2dUpdateUnzipTaskError
                                 userInfo:userInfo];
}

- (NSError *)errorForNonExistentTemplateFile:(NSString *)zipFile
{
    NSDictionary *userInfo = @{
            @"zipFile" : zipFile,
            NSLocalizedDescriptionKey : @"Project template zip file does not exist, unable to extract newer cocos2d version."};

    return [NSError errorWithDomain:SBErrorDomain
                                     code:SBCocos2dUpdateTemplateZipFileDoesNotExistError
                                 userInfo:userInfo];
}

@end