#import <Foundation/Foundation.h>
#import "ProjectSettings.h"

@interface ProjectSettings (Convenience)

- (BOOL)isPublishEnvironmentRelease;
- (BOOL)isPublishEnvironmentDebug;

- (int)soundQualityForRelPath:(NSString *)relPath targetType:(int)targetType;
- (int)soundFormatForRelPath:(NSString *)relPath targetType:(int)targetType;

@end