//
//  OpenPathsController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 19.11.14.
//
//

#import <Carbon/Carbon.h>
#import "SBOpenPathsController.h"
#import "ProjectSettings.h"
#import "NSAlert+Convenience.h"
#import "MiscConstants.h"
#import "RMPackage.h"
#import "ResourceManager.h"
#import "NotificationNames.h"

static NSString *const KEY_TYPE = @"type";
static NSString *const KEY_PACKAGE = @"package";
static NSString *const OPENPATHS_SCRIPT_NAME = @"OpenPaths.scpt";

typedef enum
{
    SBOpenPathTypeProject = 0,
    SBOpenPathTypePublishIOS,
    SBOpenPathTypePublishAndroid,
    SBOpenPathTypePublishPackage
} SBOpenPathType;


@interface SBOpenPathsController ()

@property (nonatomic, strong) NSMutableArray *packageMenuItems;
@property (nonatomic, strong) NSMutableDictionary *installedApps;
@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic) BOOL userScriptInstalled;

@end


@implementation SBOpenPathsController

- (id)init
{
    self = [super init];
    if (self)
    {
        self.packageMenuItems = [NSMutableArray array];
        self.installedApps = [NSMutableDictionary dictionary];
        self.userScriptInstalled = [self isUserScriptInstalled];

        NSLog(@"%@", [self openPathsScriptURL].path);

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMenuItemsForPackages) name:RESOURCE_PATHS_CHANGED object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)populateOpenPathsMenuItems
{
    self.menu = [[NSMenu alloc] initWithTitle:@"Open Paths"];

    [self addMenuItemsToOpenPathsMenuWithTitle:@"Project Folder" representedObject:@{KEY_TYPE : @(SBOpenPathTypeProject)}];
    [self addMenuItemsToOpenPathsMenuWithTitle:@"iOS Publish Folder" representedObject:@{KEY_TYPE : @(SBOpenPathTypePublishIOS)}];
    [self addMenuItemsToOpenPathsMenuWithTitle:@"Android Publish Folder" representedObject:@{KEY_TYPE : @(SBOpenPathTypePublishAndroid)}];
    [self addSeparator];
    [self updateMenuItemsForPackages];

    [_openPathsMenuItem setSubmenu:_menu];
}

- (void)addSeparator
{
    NSMenuItem *item = [NSMenuItem separatorItem];
    [_menu addItem:item];
}

- (void)updateMenuItemsForPackages
{
    [self removeAllPackageSubmenus];

    [self addPackagesSubmenus];
}

- (void)addPackagesSubmenus
{
    for (RMPackage *package in [[ResourceManager sharedManager] allPackages])
    {
        NSMenuItem *item2 = [self addMenuItemsToOpenPathsMenuWithTitle:package.name
                                                     representedObject:@{KEY_TYPE : @(SBOpenPathTypePublishPackage), KEY_PACKAGE : package}];

        [_packageMenuItems addObject:item2];
    }
}

- (void)removeAllPackageSubmenus
{
    for (NSMenuItem *packageSubmenu in _packageMenuItems)
    {
        NSInteger index = [_menu indexOfItem:packageSubmenu];
        if (index != -1)
        {
            [_menu removeItem:packageSubmenu];
        }
    }
}

- (NSMenuItem *)addMenuItemsToOpenPathsMenuWithTitle:(NSString *)title representedObject:(id)representedObject
{
    NSMenuItem *folderItem = [[NSMenuItem alloc] init];
    folderItem.title = title;

    NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
    [folderItem setSubmenu:menu];

    [_menu addItem:folderItem];

    NSArray *titleSelectorPairs = [self createTitleSelectorPairs];

    for (NSDictionary *entry in titleSelectorPairs)
    {
        NSMenuItem *item;
        if ([entry[@"title"] isEqualToString:@"Separator"])
        {
            item = [NSMenuItem separatorItem];
        }
        else
        {
            item = [[NSMenuItem alloc] initWithTitle:entry[@"title"]
                                                          action:NSSelectorFromString(entry[@"selector"])
                                                   keyEquivalent:@""];
            item.representedObject = representedObject;
            item.target = self;
        }

        [menu addItem:item];
    }

    return folderItem;
}

- (NSArray *)createTitleSelectorPairs
{
    NSMutableArray *result = [@[
        @{@"title" : @"Copy to Clipboard", @"selector" : @"copyToClipboard:"},
        @{@"title" : @"Separator"},
        @{@"title" : @"Open in Finder", @"selector" : @"openInFinder:"},
        @{@"title" : @"Open in Terminal", @"selector" : @"openInTerminal:"}
    ] mutableCopy];

    if ([self isAppWithNameInApplicationFolder:@"iTerm2"])
    {
        [result addObject:@{@"title" : @"Open in iTerm2", @"selector" : @"openInIterm2:"}];
    }
    return result;
}

- (BOOL)isAppWithNameInApplicationFolder:(NSString *)applicationName
{
    NSNumber *isInstalled = _installedApps[applicationName];
    if (isInstalled)
    {
        return [isInstalled boolValue];
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationPathLocalDomain = [NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES) firstObject];

    NSError *error;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:applicationPathLocalDomain error:&error];
    for (NSString *filename in contents)
    {
        if ([[applicationName stringByAppendingPathExtension:@"app"] isEqualToString:filename])
        {
            _installedApps[applicationName] = @YES;
            return YES;
        }
    }

    _installedApps[applicationName] = @NO;
    return NO;
}

- (NSString *)pathForOpenPathType:(id)representedObject
{
    SBOpenPathType type = (SBOpenPathType) [representedObject[KEY_TYPE] integerValue];
    switch (type)
    {
        case SBOpenPathTypeProject:
            return _projectSettings.projectPathDir;

        case SBOpenPathTypePublishIOS:
            return [_projectSettings.projectPathDir stringByAppendingPathComponent:_projectSettings.publishDirectory];

        case SBOpenPathTypePublishAndroid:
            return [_projectSettings.projectPathDir stringByAppendingPathComponent:_projectSettings.publishDirectoryAndroid];

        case SBOpenPathTypePublishPackage:
        {
            RMPackage *package = representedObject[KEY_PACKAGE];
            return package.fullPath;
        }
    }
    return nil;
}

- (void)copyToClipboard:(id)sender
{
    NSString *path = [self pathForOpenPathType:[sender representedObject]];
    if (!path)
    {
        return;
    }

    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:path  forType:NSStringPboardType];
}

- (void)openInIterm2:(id)sender
{
    [self openPathWithSender:sender andApplicationName:@"iTerm2"];
}

- (void)openInTerminal:(id)sender
{
    [self openPathWithSender:sender andApplicationName:@"Terminal"];
}

- (void)openInFinder:(id)sender
{
    NSString *path = [self pathForOpenPathType:[sender representedObject]];
    if (!path)
    {
        return;
    }

    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

- (void)openPathWithSender:(id)sender andApplicationName:(NSString *)applicationName
{
    NSString *path = [self pathForOpenPathType:[sender representedObject]];
    if (!path)
    {
        return;
    }

    if (!_userScriptInstalled)
    {
        [self askForUserIntentToCopyScriptToUserScripts];
        return;
    }

    [self openPath:path withApplication:applicationName];
}

- (BOOL)isUserScriptInstalled
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    return [fileManager fileExistsAtPath:[self openPathsScriptURL].path];
}

- (void)askForUserIntentToCopyScriptToUserScripts
{
    [self installScriptAlert];

    NSURL *directoryURL = [self applicationScriptDirectoryURL];

    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setDirectoryURL:directoryURL];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setPrompt:@"Select Script Folder"];
    [openPanel setMessage:[NSString stringWithFormat:@"Please select the User > Library > Application Scripts > %@ folder", bundleIdentifier]];
    [openPanel beginWithCompletionHandler:^(NSInteger result)
    {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSURL *selectedURL = [openPanel URL];
            if ([selectedURL isEqual:directoryURL])
            {
                NSURL *destinationURL = [self openPathsScriptURL];

                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSURL *sourceURL = [[NSBundle mainBundle] URLForResource:OPENPATHS_SCRIPT_NAME withExtension:nil];
                NSError *error2;
                BOOL success = [fileManager copyItemAtURL:sourceURL toURL:destinationURL error:&error2];
                if (success)
                {
                    NSAlert *alert = [NSAlert alertWithMessageText:@"Script Installed"
                                                     defaultButton:@"OK"
                                                   alternateButton:nil
                                                       otherButton:nil
                                         informativeTextWithFormat:@"The script was installed succcessfully."];

                    self.userScriptInstalled = YES;
                    [alert runModal];
                }
                else
                {
                    [NSAlert showModalDialogWithTitle:@"Error" message:[NSString stringWithFormat:@"An error occured installing the script. Trying again. Error: %@", error2]];
                    if ([error2 code] != NSFileWriteFileExistsError)
                    {
                        [self performSelector:@selector(askForUserIntentToCopyScriptToUserScripts) withObject:nil afterDelay:0.0];
                    }
                }
            }
            else
            {
                // try again because the user changed the folder path
                [self performSelector:@selector(askForUserIntentToCopyScriptToUserScripts) withObject:nil afterDelay:0.0];
            }
        }
    }];
}

- (void)installScriptAlert
{
    NSString *body =
        @"To open paths in another application Spritebuilder needs to install a script to the Application Scripts directory. <br/><br/>"
        @"Sandboxed apps are not allowed to send events to other applications without the users consent. "
        @"To give your consent please click on <b>Select Script Folder</b> in the following dialogue to install the script. <br/><br/>"
        @"<a href=\"http://www.maclife.com/article/blogs/what_sandboxing\">More info on sandboxing</a>. <br/><br/>"
        @"After installing the script you can review the script, just open <p style='font-family: monospace;'>%PATHPLACEHOLDER%</p> in your favourite editor.<b> <br/><br/>"
        @"The script won't be executed after installation.</b> <br/><br/>"
        @"To open the desired path in another application please redo the previous action. "
        @"You can delete the script anytime but the feature will stop to work and will ask you again to install the script.";

    body = [body stringByReplacingOccurrencesOfString:@"%PATHPLACEHOLDER%" withString:[self applicationScriptDirectoryURL].path];

    [NSAlert showModalDialogWithTitle:@"Installation of script needed" htmlBodyText:body];
}

- (void)openPath:(NSString *)path withApplication:(NSString *)applicationName
{
    NSUserAppleScriptTask *scriptTask = [self scriptTask];
    if (scriptTask)
    {
        NSAppleEventDescriptor *event = [self eventDescriptorForToOpenPath:path withApplicationName:applicationName];
        [scriptTask executeWithAppleEvent:event completionHandler:^(NSAppleEventDescriptor *resultEventDescriptor, NSError *error)
        {
            if (!resultEventDescriptor)
            {
                [NSAlert showModalDialogWithTitle:@"Error" message:[NSString stringWithFormat:@"An error occured opening the path: %@", error]];
            }
        }];
    }
}

- (NSAppleEventDescriptor *)eventDescriptorForToOpenPath:(NSString *)pathToOpen withApplicationName:(NSString *)applicationName
{
    // parameter
    NSAppleEventDescriptor *parameterPath = [NSAppleEventDescriptor descriptorWithString:pathToOpen];
    NSAppleEventDescriptor *parameterApplication = [NSAppleEventDescriptor descriptorWithString:applicationName];
    NSAppleEventDescriptor *parameters = [NSAppleEventDescriptor listDescriptor];
    [parameters insertDescriptor:parameterApplication atIndex:1];
    [parameters insertDescriptor:parameterPath atIndex:2];

    // target
    ProcessSerialNumber psn = {0, kCurrentProcess};
    NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];

    // function
    NSAppleEventDescriptor *function = [NSAppleEventDescriptor descriptorWithString:@"openPathInApplication"];

    // event
    NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
                                                                             eventID:kASSubroutineEvent
                                                                    targetDescriptor:target
                                                                            returnID:kAutoGenerateReturnID
                                                                       transactionID:kAnyTransactionID];

    [event setParamDescriptor:function forKeyword:keyASSubroutineName];
    [event setParamDescriptor:parameters forKeyword:keyDirectObject];

    return event;
}

- (NSUserAppleScriptTask *)scriptTask
{
    NSUserAppleScriptTask *result = nil;

    NSURL *directoryURL = [self applicationScriptDirectoryURL];
    NSError *error;
    if (directoryURL)
    {
        result = [[NSUserAppleScriptTask alloc] initWithURL:[self openPathsScriptURL] error:&error];
        if (!result)
        {
            if (![self isUserScriptInstalled])
            {
                self.userScriptInstalled = NO;
                [self askForUserIntentToCopyScriptToUserScripts];
                return nil;
            }

            [NSAlert showModalDialogWithTitle:@"Error" message:@"The path could not be opened. Make sure the script has not been altered."];
        }
    }
    else
    {
        [NSAlert showModalDialogWithTitle:@"Error" message:@"No application script folder found. Is Spritebuilder running sandboxed?"];
    }

    return result;
}

- (NSURL *)applicationScriptDirectoryURL
{
    NSError *error;
    NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationScriptsDirectory
                                                                 inDomain:NSUserDomainMask
                                                        appropriateForURL:nil
                                                                   create:YES
                                                                    error:&error];

    if (!directoryURL)
    {
        NSLog(@"Error retrieving application script directory: %@", error);
    }

    return directoryURL;
}

- (NSURL *)openPathsScriptURL
{
    return [[self applicationScriptDirectoryURL] URLByAppendingPathComponent:OPENPATHS_SCRIPT_NAME];
}

@end
