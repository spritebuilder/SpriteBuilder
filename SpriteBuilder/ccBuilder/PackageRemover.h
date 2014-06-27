#import <Foundation/Foundation.h>

@class ProjectSettings;

@interface PackageRemover : NSObject

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSFileManager *fileManager;

// Will remove package paths from the project, it won't delete the folders just the project reference
// All package names have to contain the PACKAGE_NAME_SUFFIX.
// Sends RESOURCE_PATHS_CHANGED notification if there is at least one package that was removed successfully.
// Returns NO if there was at least one error.
// In error's userInfo dictionary there'll be the "errors" key with all underlying errors
- (BOOL)removePackagesFromProject:(NSArray *)packagePaths error:(NSError **)error;

@end