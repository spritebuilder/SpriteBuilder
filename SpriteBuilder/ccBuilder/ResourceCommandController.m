#import <MacTypes.h>
#import "ResourceCommandController.h"

#import "ResourceManagerOutlineView.h"
#import "ResourceDeleteCommand.h"
#import "ResourceCreateKeyframesCommand.h"
#import "ResourceExportPackageCommand.h"
#import "ResourceShowInFinderCommand.h"
#import "ResourceOpenInExternalEditorCommand.h"
#import "ResourceToggleSmartSpriteSheetCommand.h"
#import "ResourceNewFileCommand.h"
#import "ResourceManager.h"
#import "ResourceNewFolderCommand.h"
#import "ResourceNewPackageCommand.h"
#import "CCBPublisherController.h"
#import "PublishingFinishedDelegate.h"

@interface ResourceCommandController ()
@property (nonatomic, strong) ResourcePublishPackageCommand *publishCommand;
@end

@implementation ResourceCommandController


#pragma mark - Initialization

- (NSArray *)selectedResources
{
    return _resourceManagerOutlineView.selectedResources;
}

- (void)showResourceInFinder:(id)sender
{
    ResourceShowInFinderCommand *command = [[ResourceShowInFinderCommand alloc] init];
    command.resources = [self selectedResources];
    [command execute];
}

- (void)openResourceWithExternalEditor:(id)sender
{
    ResourceOpenInExternalEditorCommand *command = [[ResourceOpenInExternalEditorCommand alloc] init];
    command.resources = [self selectedResources];
    [command execute];
}

- (void)toggleSmartSheet:(id)sender
{
    ResourceToggleSmartSpriteSheetCommand *command = [[ResourceToggleSmartSpriteSheetCommand alloc] init];
    command.resources = [self selectedResources];
    command.projectSettings = _projectSettings;
    [command execute];
}

- (void)createKeyFrameFromSelection:(id)sender
{
    ResourceCreateKeyframesCommand *command = [[ResourceCreateKeyframesCommand alloc] init];
    [command execute];
}

- (void)newFile:(id)sender
{
    ResourceNewFileCommand *command = [[ResourceNewFileCommand alloc] init];
    command.resources = [self selectedResources];
    command.outlineView = _resourceManagerOutlineView;
    command.windowForModals = _window;
    command.resourceManager = _resourceManager;
    [command execute];
}

- (void)newFolder:(id)sender
{
    ResourceNewFolderCommand *command = [[ResourceNewFolderCommand alloc] init];
    command.resources = [self selectedResources];
    command.outlineView = _resourceManagerOutlineView;
    command.resourceManager = _resourceManager;
    [command execute];
}

- (void)newPackage:(id)sender
{
    ResourceNewPackageCommand *command = [[ResourceNewPackageCommand alloc] init];
    command.outlineView = _resourceManagerOutlineView;
    command.projectSettings = _projectSettings;
    command.resourceManager = _resourceManager;
    command.windowForModals = _window;
    [command execute];
}

- (void)deleteResource:(id)sender
{
    ResourceDeleteCommand *command = [[ResourceDeleteCommand alloc] init];
    command.resources = [self selectedResources];
    command.projectSettings = _projectSettings;
    command.outlineView = _resourceManagerOutlineView;
    [command execute];
}

- (void)exportPackage:(id)sender
{
    ResourceExportPackageCommand *command = [[ResourceExportPackageCommand alloc] init];
    command.resources = [self selectedResources];
    command.windowForModals = _window;
    [command execute];
}


@end