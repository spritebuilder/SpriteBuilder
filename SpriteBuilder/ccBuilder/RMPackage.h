#import <Foundation/Foundation.h>
#import "RMDirectory.h"

// This can be removed if there is actually no difference between a directoy aka resource path or a package
// That has to be verified later on when the packages feature and migration has been fully specified
@interface RMPackage : RMDirectory

// Returns the name of the package, no path, without the .PACKAGE_NAME_SUFFIX.
// Will remove only the first occurance starting at the back of the path
@property (nonatomic, copy, readonly) NSString *name;

@end