#import <Foundation/Foundation.h>
#import "ProjectSettings.h"

@interface ProjectSettings (Packages)

@property (nonatomic, readonly) NSString *packagesFolderPath;

// Returns full path for a package name. Packages reside in a special folder within the project.
// A package name MUST NOT contain the .PACKAGE_NAME_SUFFIX
- (NSString *)fullPathForPackageName:(NSString *)packageName;

// Tests if a given path is within the packages folder, this will returns YES
// even if the path is nested deeper within subfolders within the packages folder
// This method is doing a string comparison so fancy stuff like /foo/../foo/ won't work
- (BOOL)isPathInPackagesFolder:(NSString *)path;

@end