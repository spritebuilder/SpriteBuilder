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

@interface PreviewContainerViewController ()

@property (nonatomic, strong) NSViewController <PreviewViewControllerProtocol> *currentPreviewViewController;
@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, strong) RMResource *previewedResource;

@end


@implementation PreviewContainerViewController

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

    if (self)
    {

    }

    return self;
}

- (void)setPreviewedResource:(RMResource *)previewedResource projectSettings:(ProjectSettings *)projectSettings
{
    [self resetView];

    self.projectSettings = projectSettings;

    if (![previewedResource isKindOfClass:[RMResource class]])
    {
        [self showGenericPreviewViewController];
        return;
    }

    self.previewedResource = previewedResource;
/*
    if (res.type == kCCBResTypeImage)
    {
        [self updateImagePreview:resource settings:_projectSettings res:res];
    }
    else if (res.type == kCCBResTypeDirectory && [res.data isDynamicSpriteSheet])
    {
        [self updateSpriteSheetPreview:_projectSettings res:res];
    }
    else
*/
    if (_previewedResource.type == kCCBResTypeAudio)
    {
        [self showAudioPreview];
    }
    else
    {
        [self showGenericPreviewViewController];
    }


/*
    else if (res.type == kCCBResTypeCCBFile)
    {
        [self updateCCBFilePreview:res];
    }
    else
*/
}


- (void)setView:(NSView *)newView
{
    [super setView:newView];

    [self showGenericPreviewViewController];
}

- (void)showGenericPreviewViewController
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
