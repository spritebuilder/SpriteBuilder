//  ProjectSettings2WindowController.m
//  SpriteBuilder
//
//
//  Created by Nicky Weber on 24.07.14.
//
//

#import "ProjectSettingsWindowController.h"
#import "ProjectSettings.h"
#import "SBPackageSettings.h"
#import "RMPackage.h"
#import "ResourceManager.h"
#import "NSString+RelativePath.h"
#import "MiscConstants.h"
#import "PublishUtil.h"
#import "NSAlert+Convenience.h"
#import "CCRendererBasicTypes_Private.h"

typedef void (^DirectorySetterBlock)(NSString *directoryPath);

@implementation ProjectSettingsWindowController

- (instancetype)init
{
    self = [self initWithWindowNibName:@"ProjectSettingsWindow"];
    
    if (self)
    {
        self.settingsList = [NSMutableArray array];

        [self populatePackagesSettingsList];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSIndexSet *firstRow = [[NSIndexSet alloc] initWithIndex:0];
    [_tableView selectRowIndexes:firstRow byExtendingSelection:NO];

    [self loadDetailViewForPackage:[self selectedPackageSettings]];
}

- (void)populatePackagesSettingsList
{
    for (RMPackage *package in [[ResourceManager sharedManager] allPackages])
    {
        SBPackageSettings *packagePublishSettings = [[SBPackageSettings alloc] initWithPackage:package];
        [packagePublishSettings load];

        [_settingsList addObject:packagePublishSettings];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    SBPackageSettings *packageSettings = [self selectedPackageSettings];
    if (packageSettings)
    {
        [self loadDetailViewForPackage:packageSettings];
    }
}

- (SBPackageSettings *)selectedPackageSettings
{
    return _settingsList[(NSUInteger) _tableView.selectedRow];
}

- (void)removeAllSubviewsOfDetailView
{
    for (NSView *subview in _detailView.subviews)
    {
        [subview removeFromSuperview];
    }
}

- (void)loadDetailViewForPackage:(SBPackageSettings *)settings
{
    NSAssert(settings != nil, @"packagePublishSettings must not be nil");
    self.currentPackageSettings = settings;

    [self loadViewWithNibName:@"PackageSettingsDetailView"];
}

- (void)loadViewWithNibName:(NSString *)nibName
{
    NSArray *topObjects;
    [[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:&topObjects];

    [self removeAllSubviewsOfDetailView];

    for (id object in topObjects)
    {
        if ([object isKindOfClass:[NSView class]])
        {
            [self.detailView addSubview:object];
            return;
        }
    }
}

- (IBAction)acceptSheet:(id)sender
{
    [self saveAllSettings];
    [super acceptSheet:sender];
}

- (void)saveAllSettings
{
    for (SBPackageSettings *packageSettings in _settingsList)
    {
        [packageSettings store];
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
    SBPackageSettings *packageSettings = [self selectedPackageSettings];
    if (!packageSettings)
    {
        return;
    }

    [self selectPublishCurrentPath:packageSettings.customOutputDirectory
                    dirSetterBlock:^(NSString *directoryPath)
    {
        packageSettings.customOutputDirectory = directoryPath;
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
