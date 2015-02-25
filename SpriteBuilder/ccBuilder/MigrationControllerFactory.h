//
// Created by Nicky Weber on 18.02.15.
//

#import <Foundation/Foundation.h>

@class ProjectSettings;
@class MigrationController;
@class CCBDocument;


@interface MigrationControllerFactory : NSObject

+ (MigrationController *)fullProjectMigrationControllerWithProjectSettings:(ProjectSettings *)projectSettings;

+ (MigrationController *)documentMigrationControllerWithFilePath:(NSString *)filePath renameResult:(NSMutableDictionary *)renameResult;

+ (MigrationController *)packageImportingMigrationController:(NSString *)dirPath;

@end
