#import <Foundation/Foundation.h>

@class RMResource;
@class ProjectSettings;

@protocol PreviewViewControllerProtocol <NSObject>

- (void)setPreviewedResource:(RMResource *)previewedResource projectSettings:(ProjectSettings *)projectSettings;

@end