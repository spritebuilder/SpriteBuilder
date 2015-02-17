//
// Created by Nicky Weber on 16.02.15.
//

#import <Foundation/Foundation.h>
#import "ProjectMigratorProtocol.h"


@interface AllPackageSettingsMigrator : NSObject <ProjectMigratorProtocol>

- (id)initWithProjectSettings:(ProjectSettings *)projectSettings;

@end
