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
#import "MiscConstants.h"
#import "RMPackage.h"
#import "ResourceManager.h"
#import "NotificationNames.h"

static NSString *const KEY_TYPE = @"type";
static NSString *const KEY_PACKAGE = @"package";


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

@end


@implementation SBOpenPathsController

- (id)init
{
    self = [super init];
    if (self)
    {
        self.packageMenuItems = [NSMutableArray array];
        self.installedApps = [NSMutableDictionary dictionary];

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

    [self addMenuItemsFor:@"Project Folder" representedObject:@{KEY_TYPE : @(SBOpenPathTypeProject)}];
    [self addMenuItemsFor:@"iOS Publish Folder" representedObject:@{KEY_TYPE : @(SBOpenPathTypePublishIOS)}];
    [self addMenuItemsFor:@"Android Publish Folder" representedObject:@{KEY_TYPE : @(SBOpenPathTypePublishAndroid)}];
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
        NSMenuItem *item2 = [self addMenuItemsFor:package.name
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

- (NSMenuItem *)addMenuItemsFor:(NSString *)title representedObject:(id)representedObject
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
        item.representedObject = representedObject;
        item.target = self;
        [menu addItem:item];
    }

    return folderItem;
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
    NSString *path = [self pathForOpenPathType:[sender representedObject]];
    if (!path)
    {
        return;
    }

    NSString *script = [self iTerm2OpenScriptWithPath:path];
    [self runAppleScript:script];

}

- (void)openInTerminal:(id)sender
{
    NSString *path = [self pathForOpenPathType:[sender representedObject]];
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
    NSString *path = [self pathForOpenPathType:[sender representedObject]];
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
