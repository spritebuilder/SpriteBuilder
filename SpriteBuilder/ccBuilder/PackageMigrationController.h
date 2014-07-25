#import <Foundation/Foundation.h>

/**
 * The PackageMigrationController is used to start the PackageMigrator if needed
 * since the user will be asked if she wants to migrate or not. If there are errors
 * the rollback is triggered and the error dialog is presented.
 */

@class ProjectSettings;


@interface PackageMigrationController : NSObject

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings;

- (BOOL)migrate;

@end