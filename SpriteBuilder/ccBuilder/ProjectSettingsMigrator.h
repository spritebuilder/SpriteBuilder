#import <Foundation/Foundation.h>
#import "ProjectMigratorProtocol.h"

@class ProjectSettings;
@class BackupFileCommand;


@interface ProjectSettingsMigrator : NSObject <ProjectMigratorProtocol>

- (id)initWithProjectSettings:(ProjectSettings *)projectSettings;

@end
