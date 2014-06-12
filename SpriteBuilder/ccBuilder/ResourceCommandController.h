#import <Foundation/Foundation.h>

@class ProjectSettings;
@class ResourceManagerOutlineView;
@class ResourceManager;

@interface ResourceCommandController : NSObject

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) ResourceManagerOutlineView *resourceManagerOutlineView;
@property (nonatomic, weak) NSWindow *window;
@property (nonatomic, weak) ResourceManager *resourceManager;


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