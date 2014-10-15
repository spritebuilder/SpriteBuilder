#import "PreviewBaseViewController.h"
#import "RMResource.h"
#import "ProjectSettings.h"
#import "ResourceManager.h"
#import "NotificationNames.h"

@interface PreviewBaseViewController()

- (void)setValue:(id)value withName:(NSString *)name isAudio:(BOOL)isAudio;

@end


@implementation PreviewBaseViewController

- (void)setInitialValues:(dispatch_block_t)setterBlock
{
    if (!setterBlock)
    {
        return;
    }

    self.initialUpdate = YES;

    setterBlock();

    self.initialUpdate = NO;
}

- (void)setValue:(id)value withName:(NSString *)name isAudio:(BOOL)isAudio
{
    if (!_previewedResource
        || _initialUpdate)
    {
        return;
    }

    // There's a inconsistency here for audio settings, no default values assumed by a absent key
    if ([value intValue] || isAudio)
    {
        [_projectSettings setProperty:value forResource:_previewedResource andKey:name];
    }
    else
    {
        [_projectSettings removePropertyForResource:_previewedResource andKey:name];
    }

    // Reload the resource
    [ResourceManager touchResource:_previewedResource];
    [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCES_CHANGED object:nil];
}

@end