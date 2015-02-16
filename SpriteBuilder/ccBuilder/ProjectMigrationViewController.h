//
// Created by Nicky Weber on 13.02.15.
//

#import <Foundation/Foundation.h>
#import "ProjectMigrationControllerDelegate.h"

@class ProjectSettings;
@class ProjectMigrationController;


@interface ProjectMigrationViewController : NSObject <ProjectMigrationControllerDelegate>

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings;

- (BOOL)migrate;

@end