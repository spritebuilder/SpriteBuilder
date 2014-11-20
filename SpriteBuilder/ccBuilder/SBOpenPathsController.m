//
//  OpenPathsController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 19.11.14.
//
//

#import "SBOpenPathsController.h"
#import "ProjectSettings.h"
#import "NSAlert+Convenience.h"
#import "ProjectSettings+Packages.h"
#import "MiscConstants.h"

typedef enum
{
    SBOpenPathTypeProject = 0,
    SBOpenPathTypePublishIOS,
    SBOpenPathTypePublishAndroid
} SBOpenPathType;


@interface SBOpenPathsController ()

@property (nonatomic, strong) NSMenu *menu;

@end


@implementation SBOpenPathsController

- (void)setProjectSettings:(ProjectSettings *)projectSettings
{
    _projectSettings = projectSettings;

    if (_projectSettings)
    {
        [self populateOpenPathsMenuItem];
    }
    else
    {
        [_openPathsMenuItem setSubmenu:nil];
    }
}

- (void)populateOpenPathsMenuItem
{
     self.menu = [[NSMenu alloc] initWithTitle:@"Open Paths"];
    
    [self populateMenu];

    [_openPathsMenuItem setSubmenu:_menu];
}

- (void)populateMenu
{
    [self addMenuItemsFor:@"Project Folder" openPathType:SBOpenPathTypeProject];
    [self addMenuItemsFor:@"iOS Publish Folder" openPathType:SBOpenPathTypePublishIOS];
    [self addMenuItemsFor:@"Android Publish Folder" openPathType:SBOpenPathTypePublishAndroid];
}

- (void)addMenuItemsFor:(NSString *)title openPathType:(SBOpenPathType)openPathType
{
    NSMenuItem *folderItem = [[NSMenuItem alloc] init];
    folderItem.title = title;

    NSMenu *menu = [[NSMenu alloc] initWithTitle:title];
    [folderItem setSubmenu:menu];

    [_menu addItem:folderItem];

    NSMutableDictionary *titleSelectorPairs = [@{
            @"Open in Finder" : @"openInFinder:",
            @"Copy to Clipboard" : @"copyToClipboard:",
    } mutableCopy];

    [self addExtraOptionsToDictionary:titleSelectorPairs];

    for (NSString *key in titleSelectorPairs)
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:key
                                                      action:NSSelectorFromString(titleSelectorPairs[key])
                                               keyEquivalent:@""];
        item.representedObject = @(openPathType);
        item.target = self;
        [menu addItem:item];
    }
}

- (void)addExtraOptionsToDictionary:(NSMutableDictionary *)titleSelectorPairs
{
    if (!APP_STORE_VERSION)
    {
        titleSelectorPairs[@"Open in Terminal"] = @"openInTerminal:";

        if ([self isAppWithNameInApplicationFolder:@"iTerm2"])
        {
            titleSelectorPairs[@"Open in iTerm2"] = @"openInIterm2:";
        }
    }
}

- (BOOL)isAppWithNameInApplicationFolder:(NSString *)applicationName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationPathLocalDomain = [NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES) firstObject];

    NSError *error;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:applicationPathLocalDomain error:&error];
    for (NSString *filename in contents)
    {
        if ([[applicationName stringByAppendingPathExtension:@"app"] isEqualToString:filename])
        {
            return YES;
        }
    }

    return NO;
}

- (NSString *)pathForOpenPathType:(SBOpenPathType)openPathType
{
    switch (openPathType)
    {
        case SBOpenPathTypeProject:
            return _projectSettings.projectPathDir;

        case SBOpenPathTypePublishIOS:
            return [_projectSettings.projectPathDir stringByAppendingPathComponent:_projectSettings.publishDirectory];

        case SBOpenPathTypePublishAndroid:
            return [_projectSettings.projectPathDir stringByAppendingPathComponent:_projectSettings.publishDirectoryAndroid];
    }
    return nil;
}

- (void)copyToClipboard:(id)sender
{
    NSString *path = [self pathForOpenPathType:(SBOpenPathType) [[sender representedObject] integerValue]];
    if (!path)
    {
        return;
    }

    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:path  forType:NSStringPboardType];
}

- (void)openInIterm2:(id)sender
{
    NSString *path = [self pathForOpenPathType:(SBOpenPathType) [[sender representedObject] integerValue]];
    if (!path)
    {
        return;
    }

    NSString *script = [self iTerm2OpenScriptWithPath:path];
    [self runAppleScript:script];

}

- (void)openInTerminal:(id)sender
{
    NSString *path = [self pathForOpenPathType:(SBOpenPathType) [[sender representedObject] integerValue]];
    if (!path)
    {
        return;
    }

    NSString *script = [self terminalOpenScriptWithPath:path];
    [self runAppleScript:script];
}

- (void)runAppleScript:(NSString *)script
{
    NSAppleScript *applescript = [[NSAppleScript alloc] initWithSource:script];
    NSDictionary *error;
    if (![applescript executeAndReturnError:&error])
    {
        [NSAlert showModalDialogWithTitle:@"Error" message:[NSString stringWithFormat:@"An error occured opening the path in Terminal"]];
        NSLog(@"%@, %@", script, error);
    }
}

- (void)openInFinder:(id)sender
{
    NSString *path = [self pathForOpenPathType:(SBOpenPathType) [[sender representedObject] integerValue]];
    if (!path)
    {
        return;
    }

    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

- (NSString *)terminalOpenScriptWithPath:(NSString *)path
{
    NSString *script =
            @"tell application \"Terminal\"\n"
            "  if not (exists window 1) then reopen\n"
            "  activate\n"
            "  do script \"cd %@\"\n"
            "end tell";

    return [NSString stringWithFormat:script, path];
}

- (NSString *)iTerm2OpenScriptWithPath:(NSString *)path
{
    NSString *script =
        @"tell application \"iTerm2\"\n"
                "   activate\n"
                "   try\n"
                "      set _session to current session of current terminal\n"
                "   on error\n"
                "      set _term to (make new terminal)\n"
                "      tell _term\n"
                "         launch session \"Default\"\n"
                "         set _session to current session\n"
                "      end tell\n"
                "   end try\n"
                "   tell _session\n"
                "      write text \"cd %@\"\n"
                "   end tell\n"
                "end tell\n";
    return [NSString stringWithFormat:script, path];
}

@end
