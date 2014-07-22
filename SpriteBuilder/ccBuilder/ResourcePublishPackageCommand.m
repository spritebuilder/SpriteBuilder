#import "ResourceCommandContextMenuProtocol.h"

#import "ResourcePublishPackageCommand.h"
#import "ProjectSettings.h"
#import "RMPackage.h"
#import "TaskStatusWindow.h"
#import "CCBDirectoryPublisher.h"
#import "CCBWarnings.h"
#import "CCBPublisherController.h"
#import "PackageSettings.h"
#import "ProjectSettings+Convenience.h"


@interface ResourcePublishPackageCommand()

@property (nonatomic, strong) TaskStatusWindow *modalTaskStatusWindow;
@property (nonatomic, strong) CCBPublisherController *publisherController;

@end


@implementation ResourcePublishPackageCommand

- (void)execute
{
    NSAssert(_projectSettings != nil, @"projectSettings must not be nil");
    NSAssert(_windowForModals != nil, @"windowForModals must not be nil");

    NSArray *filteredPackages = [self selectedPackages];
    if (filteredPackages.count == 0)
    {
        return;
    }

    NSOpenPanel *publishPanel = [self publishPanel];
    [publishPanel beginSheetModalForWindow:_windowForModals
                         completionHandler:^(NSInteger result)
    {
        if (result == NSFileHandlingPanelOKButton)
        {
            self.publishDirectory = publishPanel.directoryURL.path;
            [self publishPackages:filteredPackages];
        }
    }];
}

- (void)publishPackages:(NSArray *)filteredPackages
{
    self.publisherController = [[CCBPublisherController alloc] init];

    _publisherController.publishMainProject = NO;
    _publisherController.projectSettings = _projectSettings;
    _publisherController.packageSettings = [self packageSettingsForPackages:filteredPackages];

    self.modalTaskStatusWindow = [[TaskStatusWindow alloc] initWithWindowNibName:@"TaskStatusWindow"];
    _publisherController.taskStatusUpdater = _modalTaskStatusWindow;

    ResourcePublishPackageCommand __weak *weakSelf = self;
    _publisherController.finishBlock = ^(CCBPublisher *publisher, CCBWarnings *warnings)
    {
        [weakSelf closeStatusWindow];
        if (weakSelf.finishBlock)
        {
            weakSelf.finishBlock(publisher, warnings);
        }
    };

    [_publisherController startAsync:YES];

    [self modalStatusWindowStartWithTitle:@"Publishing Packages" isIndeterminate:NO onCancelBlock:^
    {
        [_publisherController cancel];
        [self closeStatusWindow];
        if (weakSelf.cancelBlock)
        {
            weakSelf.cancelBlock();
        }
    }];

    [self modalStatusWindowUpdateStatusText:@"Starting up..."];
}

- (NSMutableArray *)packageSettingsForPackages:(NSArray *)filteredPackages
{
    NSMutableArray *packageSettingsToPublish = [NSMutableArray array];

    for (RMPackage *package in filteredPackages)
    {
        PackageSettings *packageSettings = [[PackageSettings alloc] initWithPackage:package];

        [packageSettings setPublishResolutions:[_projectSettings publishingResolutionsForOSType:kCCBPublisherOSTypeIOS] forOSType:kCCBPublisherOSTypeIOS];
        [packageSettings setPublishResolutions:[_projectSettings publishingResolutionsForOSType:kCCBPublisherOSTypeAndroid] forOSType:kCCBPublisherOSTypeAndroid];
        packageSettings.outputDirectory = _publishDirectory;
        [packageSettings setPublishEnabled:_projectSettings.publishEnablediPhone forOSType:kCCBPublisherOSTypeIOS];
        [packageSettings setPublishEnabled:_projectSettings.publishEnabledAndroid forOSType:kCCBPublisherOSTypeAndroid];
        packageSettings.publishEnvironment = _projectSettings.publishEnvironment;

        [packageSettingsToPublish addObject:packageSettings];
    }
    return packageSettingsToPublish;
}

- (NSOpenPanel *)publishPanel
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [openPanel setCanCreateDirectories:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setPrompt:@"Publish"];

    return openPanel;
}

- (NSArray *)selectedPackages
{
    NSMutableArray *result = [NSMutableArray array];

    for (id resource in _resources)
    {
        if ([resource isKindOfClass:[RMPackage class]])
        {
            [result addObject:resource];
        }
    }

    return result;
}

- (void)closeStatusWindow
{
    _modalTaskStatusWindow.indeterminate = YES;
    _modalTaskStatusWindow.onCancelBlock = nil;
    [[NSApplication sharedApplication] stopModal];
    [_modalTaskStatusWindow.window orderOut:self];
    _modalTaskStatusWindow = nil;
}

- (void) modalStatusWindowUpdateStatusText:(NSString*) text
{
    [_modalTaskStatusWindow updateStatusText:text];
}

- (void)modalStatusWindowStartWithTitle:(NSString *)title isIndeterminate:(BOOL)isIndeterminate onCancelBlock:(OnCancelBlock)onCancelBlock
{
    if (!_modalTaskStatusWindow)
    {
        self.modalTaskStatusWindow = [[TaskStatusWindow alloc] initWithWindowNibName:@"TaskStatusWindow"];
    }

    _modalTaskStatusWindow.indeterminate = isIndeterminate;
    _modalTaskStatusWindow.onCancelBlock = onCancelBlock;
    _modalTaskStatusWindow.window.title = title;
    [_modalTaskStatusWindow.window center];
    [_modalTaskStatusWindow.window makeKeyAndOrderFront:self];

    [[NSApplication sharedApplication] runModalForWindow:_modalTaskStatusWindow.window];
}


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"Publish Package...";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return ([resources.firstObject isKindOfClass:[RMPackage class]]);
}

@end