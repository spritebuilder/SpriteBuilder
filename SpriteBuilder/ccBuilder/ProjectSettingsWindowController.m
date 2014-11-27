//  ProjectSettings2WindowController.m
//  SpriteBuilder
//
//
//  Created by Nicky Weber on 24.07.14.
//
//

#import "ProjectSettingsWindowController.h"
#import "ProjectSettings.h"
#import "PackagePublishSettings.h"
#import "PackageSettingsDetailView.h"
#import "RMPackage.h"
#import "ResourceManager.h"
#import "MainProjectSettingsDetailView.h"
#import "NSString+RelativePath.h"
#import "MiscConstants.h"
#import "PublishUtil.h"
#import "NSAlert+Convenience.h"

typedef void (^DirectorySetterBlock)(NSString *directoryPath);

@interface SettingsListEntry : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic) BOOL canBeModified;
@property (nonatomic, strong) PackagePublishSettings *packagePublishSettings;

@end


@implementation SettingsListEntry

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.canBeModified = NO;
    }
    return self;
}

- (NSString *)name
{
    if (_packagePublishSettings)
    {
        return _packagePublishSettings.package.name;
    }
    return @"Main Project";
}

@end


#pragma mark --------------------------------

@implementation ProjectSettingsWindowController

- (instancetype)init
{
    self = [self initWithWindowNibName:@"ProjectSettingsWindow"];
    
    if (self)
    {
        self.settingsList = [NSMutableArray array];

        [self populateSettingsList];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSIndexSet *firstRow = [[NSIndexSet alloc] initWithIndex:0];
    [_tableView selectRowIndexes:firstRow byExtendingSelection:NO];

    [self loadMainProjectSettingsView];
}

- (void)populateSettingsList
{
    SettingsListEntry *mainProjectEntry = [[SettingsListEntry alloc] init];
    [_settingsList addObject:mainProjectEntry];

    for (RMPackage *package in [[ResourceManager sharedManager] allPackages])
    {
        PackagePublishSettings *packagePublishSettings = [[PackagePublishSettings alloc] initWithPackage:package];
        [packagePublishSettings load];

        SettingsListEntry *packageEntry = [[SettingsListEntry alloc] init];
        packageEntry.packagePublishSettings = packagePublishSettings;

        [_settingsList addObject:packageEntry];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    SettingsListEntry *listEntry = _settingsList[(NSUInteger) _tableView.selectedRow];
    if (listEntry.packagePublishSettings)
    {
        [self loadDetailViewForPackage:listEntry.packagePublishSettings];
    }
    else
    {
        [self loadMainProjectSettingsView];
    }
}

- (void)removeAllSubviewsOfDetailView
{
    for (NSView *subview in _detailView.subviews)
    {
        [subview removeFromSuperview];
    }
}

- (void)loadMainProjectSettingsView
{
    MainProjectSettingsDetailView *view = [self loadViewWithNibName:@"MainProjectSettingsDetailView" viewClass:[MainProjectSettingsDetailView class]];

    view.showAndroidSettings = YES;
}

- (void)loadDetailViewForPackage:(PackagePublishSettings *)settings
{
    NSAssert(settings != nil, @"packagePublishSettings must not be nil");
    self.currentPackageSettings = settings;

    PackageSettingsDetailView *view = [self loadViewWithNibName:@"PackageSettingsDetailView" viewClass:[PackageSettingsDetailView class]];

    view.showAndroidSettings = YES;
}

- (id)loadViewWithNibName:(NSString *)nibName viewClass:(Class)viewClass
{
    NSArray *topObjects;
    [[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:&topObjects];

    [self removeAllSubviewsOfDetailView];

    for (id object in topObjects)
    {
        if ([object isKindOfClass:viewClass])
        {
            [self.detailView addSubview:object];
            return object;
        }
    }
    return nil;
}

- (IBAction)acceptSheet:(id)sender
{
    [self saveAllSettings];
    [super acceptSheet:sender];
}

- (void)saveAllSettings
{
    for (SettingsListEntry *listEntry in _settingsList)
    {
        [listEntry.packagePublishSettings store];
    }
    [_projectSettings store];
}

- (IBAction)selectPublishDirectoryIOS:(id)sender
{
    [self selectPublishCurrentPath:_projectSettings.publishDirectory
                    dirSetterBlock:^(NSString *directoryPath) {
        _projectSettings.publishDirectory = directoryPath;
    }];
}

- (IBAction)selectPublishDirectoryAndroid:(id)sender
{
    [self selectPublishCurrentPath:_projectSettings.publishDirectoryAndroid
                    dirSetterBlock:^(NSString *directoryPath)
    {
        _projectSettings.publishDirectoryAndroid = directoryPath;
    }];
}

- (IBAction)selectPackagePublishingCustomDirectory:(id)sender;
{
    SettingsListEntry *listEntry = _settingsList[(NSUInteger) _tableView.selectedRow];
    if (!listEntry.packagePublishSettings)
    {
        return;
    }

    [self selectPublishCurrentPath:listEntry.packagePublishSettings.customOutputDirectory
                    dirSetterBlock:^(NSString *directoryPath)
    {
        listEntry.packagePublishSettings.customOutputDirectory = directoryPath;
    }];
}

- (void)selectPublishCurrentPath:(NSString *)currentPath dirSetterBlock:(DirectorySetterBlock)dirSetterBlock
{
    if (!dirSetterBlock)
    {
        return;
    }

    NSString *projectDir = [_projectSettings.projectPath stringByDeletingLastPathComponent];
    NSURL *openDirectory = currentPath
        ? [NSURL fileURLWithPath:[currentPath absolutePathFromBaseDirPath:projectDir]]
        : [NSURL fileURLWithPath:projectDir];

    if (!openDirectory)
    {
        return;
    }

    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setCanCreateDirectories:YES];
    [openDlg setDirectoryURL:openDirectory];
    openDlg.delegate = self;

    [openDlg beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
    {
        if (result == NSOKButton)
        {
            NSArray *files = [openDlg URLs];
            for (NSUInteger i = 0; i < [files count]; i++)
            {
                NSString *dirName = [files[i] path];
                dirSetterBlock([dirName relativePathFromBaseDirPath:projectDir]);
            }
        }
    }];
}

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
    PublishDirectoryDeletionRisk risk = [PublishUtil riskForPublishDirectoryBeingDeletedUponPublish:url.path
                                                                                      projectSettings:_projectSettings];
    if (risk == PublishDirectoryDeletionRiskSafe)
    {
        return YES;
    }

    if (risk == PublishDirectoryDeletionRiskDirectoryContainingProject)
    {
        [NSAlert showModalDialogWithTitle:@"Error" message:@"Chosen directory contains project directory. Please choose another one."];
        return NO;
    }

    if (risk == PublishDirectoryDeletionRiskNonEmptyDirectory)
    {
        NSInteger warningResult = [[NSAlert alertWithMessageText:@"Warning"
                                                   defaultButton:@"Yes"
                                                 alternateButton:@"No"
                                                     otherButton:nil
                                       informativeTextWithFormat:@"%@", @"The chosen directory is not empty, its contents will be deleted upon publishing. Are you sure?"] runModal];

        return warningResult == NSAlertDefaultReturn;
    }
    return YES;
}

@end
