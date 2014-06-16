#import <Foundation/Foundation.h>
#import "ProjectSettings.h"

@interface ProjectSettings (Packages)

// Returns full path for a package name. Packages reside in a special folder within the project.
- (NSString *)fullPathForPackageName:(NSString *)packageName;

@end