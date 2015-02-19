//
// Created by Nicky Weber on 18.02.15.
//

#import <Foundation/Foundation.h>

@class ProjectSettings;
@class MigrationController;


@interface MigrationControllerFactory : NSObject

+ (MigrationController *)fullProjectMigrationControllerWithProjectSettings:(ProjectSettings *)projectSettings;

+ (MigrationController *)documentMigrationControllerWithFilepath:(NSString *)filepath;

@end
