#import <Foundation/Foundation.h>
#import "ProjectMigratorProtocol.h"

@class ProjectSettings;


@interface ResourcePathToPackageMigrator : NSObject  <ProjectMigratorProtocol>

- (id)initWithProjectSettings:(ProjectSettings *)projectSettings;

@end
