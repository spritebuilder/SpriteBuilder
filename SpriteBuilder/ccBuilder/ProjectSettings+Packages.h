#import <Foundation/Foundation.h>
#import "ProjectSettings.h"

@interface ProjectSettings (Packages)

// Returns full path for a package name. Packages reside in a special folder within the project.
// A package name MUST NOT contain the .PACKAGE_NAME_SUFFIX
- (NSString *)fullPathForPackageName:(NSString *)packageName;

@end