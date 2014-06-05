#import <Foundation/Foundation.h>

@class ProjectSettings;

@interface ResourceActionController : NSObject


@property (nonatomic, strong) ProjectSettings *projectSettings;


+ (id)sharedController;

- (void)showResourceInFinder:(id)sender;
- (void)openResourceWithExternalEditor:(id)sender;

- (void)toggleSmartSheet:(id)sender;

- (void)createKeyFrameFromSelection:(id)sender;

- (void)newFile:(id)sender;
- (void)newFileWithResource:(id)resource outlineView:(NSOutlineView *)outlineView;

- (void)newFolder:(id)sender;
- (void)newFolderWithResource:(id)resource outlineView:(NSOutlineView *)outlineView;

- (void)deleteResource:(id)sender;

- (void)exportPackage:(id)sender;

@end