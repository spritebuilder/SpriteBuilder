#import <Foundation/Foundation.h>

@class ProjectSettings;
@class ResourceManagerOutlineView;

@interface ResourceActionController : NSObject

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) ResourceManagerOutlineView *resourceManagerOutlineView;


+ (id)sharedController;

- (void)showResourceInFinder:(id)sender;
- (void)openResourceWithExternalEditor:(id)sender;

- (void)toggleSmartSheet:(id)sender;

- (void)createKeyFrameFromSelection:(id)sender;

- (void)newFile:(id)sender;

- (void)newFileWithResource:(id)resource;

- (void)newFolder:(id)sender;

- (void)newFolderWithResource:(id)resource;

- (void)deleteResource:(id)sender;
- (void)deleteResources:(NSArray *)resources;

- (void)exportPackage:(id)sender;

@end