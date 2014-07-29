#import <Foundation/Foundation.h>
#import "ResourceManager.h"

@interface ResourceManager (Publishing)

- (NSArray *)loadAllPackageSettings;

- (NSArray *)oldResourcePaths;
@end