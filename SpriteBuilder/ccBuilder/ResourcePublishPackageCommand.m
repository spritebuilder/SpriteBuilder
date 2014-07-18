#import "ResourceCommandContextMenuProtocol.h"

#import "ResourcePublishPackageCommand.h"
#import "ProjectSettings.h"
#import "RMPackage.h"
#import "TaskStatusWindow.h"
#import "CCBDirectoryPublisher.h"
#import "CCBWarnings.h"

@interface ResourcePublishPackageCommand()

@property (nonatomic, strong) TaskStatusWindow *modalTaskStatusWindow;

@end


@implementation ResourcePublishPackageCommand

- (void)execute
{
    CCBWarnings* warnings = [[CCBWarnings alloc] init];
    warnings.warningsDescription = @"Package Publisher Warnings";

    id __weak weakSelf = self;
    CCBDirectoryPublisher *publisher = [[CCBDirectoryPublisher alloc] initWithProjectSettings:_projectSettings
                                                                   warnings:warnings
                                                              finishedBlock:^(CCBDirectoryPublisher *aPublisher, CCBWarnings *someWarnings)
    {
        [weakSelf closeStatusWindow];
    }];

    self.modalTaskStatusWindow = [[TaskStatusWindow alloc] initWithWindowNibName:@"TaskStatusWindow"];
    publisher.taskStatusUpdater = _modalTaskStatusWindow;

    NSAssert(0, @"setPublishOutputDirectory undefined!");

    // TODO!!
    [publisher setPublishOutputDirectory:@"" forTargetType:kCCBPublisherTargetTypeIPhone];
    [publisher setPublishOutputDirectory:@"" forTargetType:kCCBPublisherTargetTypeAndroid];

    NSString *pathToBePublished = ((RMPackage *)_resources.firstObject).fullPath;
    publisher.publishInputDirectories = @[pathToBePublished];

    [publisher startAsync];
    [self modalStatusWindowStartWithTitle:@"Publishing Package" isIndeterminate:NO onCancelBlock:^
    {
        [publisher cancel];
    }];
    [self modalStatusWindowUpdateStatusText:@"Starting up..."];
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
    return @"Publish Package";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return ([resources.firstObject isKindOfClass:[RMPackage class]]);
}

@end