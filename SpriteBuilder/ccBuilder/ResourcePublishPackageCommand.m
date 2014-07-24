#import "ResourceCommandContextMenuProtocol.h"

#import "ResourcePublishPackageCommand.h"
#import "ProjectSettings.h"
#import "RMPackage.h"
#import "TaskStatusWindow.h"
#import "CCBDirectoryPublisher.h"
#import "CCBWarnings.h"
#import "CCBPublisherController.h"
#import "PackagePublishSettings.h"
#import "PublishOSSettings.h"
#import "ProjectSettings+Convenience.h"
#import "PackagePublishAccessoryView.h"


@interface ResourcePublishPackageCommand()

@property (nonatomic, strong) TaskStatusWindow *modalTaskStatusWindow;
@property (nonatomic, strong) CCBPublisherController *publisherController;
@property (nonatomic, strong) PackagePublishAccessoryView *accessoryView;

@end


@implementation ResourcePublishPackageCommand

- (void)execute
{
    NSAssert(_projectSettings != nil, @"projectSettings must not be nil");
    NSAssert(_windowForModals != nil, @"windowForModals must not be nil");

    RMPackage *package = _resources.firstObject;
    self.settings = [[PackagePublishSettings alloc] initWithPackage:package];
    if (![_settings load])
    {
        [self callFinishBlockWithPublishError:package];
        return;
    }

    [self showPublishPanel];
}

- (void)showPublishPanel
{
    NSOpenPanel *publishPanel = [self publishPanel];
    [publishPanel beginSheetModalForWindow:_windowForModals
                         completionHandler:^(NSInteger result)
    {
        if (result == NSFileHandlingPanelOKButton)
        {
            self.publishDirectory = publishPanel.directoryURL.path;
            [_settings store];
            [self publishPackage];
        }
    }];
}

- (void)callFinishBlockWithPublishError:(RMPackage *)package
{
    if (_finishBlock)
    {
        CCBWarnings *warnings = [[CCBWarnings alloc] init];
        warnings.currentOSType = kCCBPublisherOSTypeNone;
        NSString *warningText = [NSString stringWithFormat:@"Error publishing package \"%@\". Could not load Package.plist for package.", package.name];
        [warnings addWarningWithDescription:warningText isFatal:YES];
        _finishBlock(nil, warnings);
    }
}

- (void)publishPackage
{
    self.publisherController = [[CCBPublisherController alloc] init];
    _settings.outputDirectory = _publishDirectory;

    _publisherController.publishMainProject = NO;
    _publisherController.projectSettings = _projectSettings;
    _publisherController.packageSettings = @[_settings];

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

- (NSOpenPanel *)publishPanel
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];

    [self addAccessoryViewToPanel:openPanel];

    [openPanel setCanCreateDirectories:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setPrompt:@"Publish"];

    return openPanel;
}

- (void)addAccessoryViewToPanel:(NSOpenPanel *)openPanel
{
    NSArray *topObjects;
    [[NSBundle mainBundle] loadNibNamed:@"PackagePublishAccessoryView" owner:self topLevelObjects:&topObjects];
    for (id object in topObjects)
    {
        if ([object isKindOfClass:[PackagePublishAccessoryView class]])
        {
            self.accessoryView = object;
            openPanel.accessoryView = _accessoryView;

            #ifdef SPRITEBUILDER_PRO
            _accessoryView.showAndroidSettings = YES;
            #else
            _accessoryView.showAndroidSettings = NO;
            #endif

            return;
        }
    }
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