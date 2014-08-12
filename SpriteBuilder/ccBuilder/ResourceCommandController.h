#import <Foundation/Foundation.h>

@class ProjectSettings;
@class ResourceManagerOutlineView;
@class ResourceManager;
@class CCBPublisherController;
@protocol PublishingFinishedDelegate;
@class ResourcePublishPackageCommand;

@interface ResourceCommandController : NSObject

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) ResourceManagerOutlineView *resourceManagerOutlineView;
@property (nonatomic, weak) NSWindow *window;
@property (nonatomic, weak) ResourceManager *resourceManager;
@property (nonatomic, weak) id<PublishingFinishedDelegate> publishDelegate;

- (void)showResourceInFinder:(id)sender;
- (void)openResourceWithExternalEditor:(id)sender;

- (void)toggleSmartSheet:(id)sender;

- (void)createKeyFrameFromSelection:(id)sender;

- (void)newFile:(id)sender;
- (void)newFolder:(id)sender;
- (void)newPackage:(id)sender;
- (void)deleteResource:(id)sender;

- (void)exportPackage:(id)sender;

@end