#import <Foundation/Foundation.h>

@class ProjectSettings;


@interface ResourcePropertiesMigrator : NSObject

- (id)initWithProjectSettings:(ProjectSettings *)settings;

- (BOOL)migrate;

@end