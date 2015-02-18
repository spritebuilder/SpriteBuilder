#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"

@class ProjectSettings;


@interface ResourcePathToPackageMigrator : NSObject  <MigratorProtocol>

- (id)initWithProjectSettings:(ProjectSettings *)projectSettings;

@end
