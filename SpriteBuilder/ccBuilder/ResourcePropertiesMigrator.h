#import <Foundation/Foundation.h>
#import "ProjectMigratorProtocol.h"

@class ProjectSettings;


@interface ResourcePropertiesMigrator : NSObject <ProjectMigratorProtocol>

- (BOOL)migrate;

@end