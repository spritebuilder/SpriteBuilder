#import <Foundation/Foundation.h>

@class ProjectSettings;


@interface PackageMigrator : NSObject

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings;

- (BOOL)migrate:(NSError **)error;

@end