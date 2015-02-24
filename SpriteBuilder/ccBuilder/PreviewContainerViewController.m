//
//  PreviewContainerViewController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 26.08.14.
//
//

#import "PreviewContainerViewController.h"
#import "PreviewGenericViewController.h"
#import "RMResource.h"
#import "ProjectSettings.h"
#import "PreviewAudioViewController.h"
#import "ResourceTypes.h"
#import "PreviewImageViewController.h"
#import "PreviewSpriteSheetViewController.h"
#import "RMDirectory.h"
#import "PreviewCCBViewController.h"

@interface PreviewContainerViewController ()

@property (nonatomic, strong) NSViewController <PreviewViewControllerProtocol> *currentPreviewViewController;
@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, strong) RMResource *previewedResource;

@end


@implementation PreviewContainerViewController

- (void)setPreviewedResource:(RMResource *)previewedResource projectSettings:(ProjectSettings *)projectSettings
{
    [self resetView];

    self.projectSettings = projectSettings;

    if (![previewedResource isKindOfClass:[RMResource class]])
    {
        [self showNoPreviewAvailable];
        return;
    }

    self.previewedResource = previewedResource;

    if (_previewedResource.type == kCCBResTypeImage)
    {
        [self showImagePreview];
    }
    else if (_previewedResource.type == [_previewedResource isSpriteSheet])
    {
        [self showSpriteSheetPreview];
    }
    else if (_previewedResource.type == kCCBResTypeAudio)
    {
        [self showAudioPreview];
    }
    else if (_previewedResource.type == kCCBResTypeSBFile)
    {
        [self showCCBPreivew];
    }
    else
    {
        [self showNoPreviewAvailable];
    }
}

- (void)showCCBPreivew
{
    [self resetView];

    self.currentPreviewViewController = [[PreviewCCBViewController alloc] initWithNibName:@"PreviewCCBView"
                                                                                       bundle:nil];

    [self addCurrentViewControllersViewToContainer];

    [_currentPreviewViewController setPreviewedResource:_previewedResource projectSettings:_projectSettings];
}

- (void)setView:(NSView *)newView
{
    [super setView:newView];

    [self showNoPreviewAvailable];
}

- (void)showNoPreviewAvailable
{
    [self resetView];

    self.currentPreviewViewController = [[PreviewGenericViewController alloc] initWithNibName:@"PreviewGenericView"
                                                                                       bundle:nil];

    [self addCurrentViewControllersViewToContainer];
}

- (void)showAudioPreview
{
    [self resetView];

    self.currentPreviewViewController = [[PreviewAudioViewController alloc] initWithNibName:@"PreviewAudioView"
                                                                                     bundle:nil];

    [self addCurrentViewControllersViewToContainer];

    [_currentPreviewViewController setPreviewedResource:_previewedResource projectSettings:_projectSettings];
}

- (void)showImagePreview
{
    [self resetView];

    self.currentPreviewViewController = [[PreviewImageViewController alloc] initWithNibName:@"PreviewImageView"
                                                                                     bundle:nil];

    [self addCurrentViewControllersViewToContainer];

    [_currentPreviewViewController setPreviewedResource:_previewedResource projectSettings:_projectSettings];
}

- (void)showSpriteSheetPreview
{
    [self resetView];

    self.currentPreviewViewController = [[PreviewSpriteSheetViewController alloc] initWithNibName:@"PreviewSpriteSheetView"
                                                                                           bundle:nil];

    [self addCurrentViewControllersViewToContainer];

    [_currentPreviewViewController setPreviewedResource:_previewedResource projectSettings:_projectSettings];
}


- (void)addCurrentViewControllersViewToContainer
{
    [self.view addSubview:_currentPreviewViewController.view];

    _currentPreviewViewController.view.frame = NSMakeRect(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)resetView
{
    [_currentPreviewViewController.view removeFromSuperview];
}


#pragma mark Split view constraints

- (CGFloat) splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (proposedMinimumPosition < 220) return 220;
    else return proposedMinimumPosition;
}

- (CGFloat) splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    float max = (float) (splitView.frame.size.height - 100);
    if (proposedMaximumPosition > max) return max;
    else return proposedMaximumPosition;
}

@end
