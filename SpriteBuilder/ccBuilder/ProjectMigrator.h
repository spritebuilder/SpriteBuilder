#import <Foundation/Foundation.h>

@class ProjectSettings;

@interface ProjectMigrator : NSObject

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings;

- (BOOL)migrate;

@end