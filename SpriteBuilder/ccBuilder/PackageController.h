#import <Foundation/Foundation.h>

@protocol PackageCreateDelegateProtocol;
@class ProjectSettings;


@interface PackageController : NSObject <PackageCreateDelegateProtocol>


@property (nonatomic, strong) ProjectSettings *projectSettings;

- (void)showCreateNewPackageDialogForWindow:(NSWindow *)window;

- (void)importPackage:(NSString *)packagePath;

// Removesa packages from project, not deleting the folders, and send a RESOURCE_PATHS_CHANGED notification after finishing
// to reload resources and update view for example
- (void)removePackagesFromProject:(NSArray *)packagePaths;

@end