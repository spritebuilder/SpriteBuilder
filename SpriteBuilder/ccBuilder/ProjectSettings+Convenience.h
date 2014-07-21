#import <Foundation/Foundation.h>

#import "ProjectSettings.h"
#import "CCBWarnings.h"

@interface ProjectSettings (Convenience)

- (BOOL)isPublishEnvironmentRelease;
- (BOOL)isPublishEnvironmentDebug;

- (int)soundQualityForRelPath:(NSString *)relPath targetType:(CCBPublisherOSType)targetType;
- (int)soundFormatForRelPath:(NSString *)relPath targetType:(CCBPublisherOSType)targetType;

- (NSArray *)publishingResolutionsForTargetType:(CCBPublisherOSType)targetType;

- (NSString *)publishDirForTargetType:(CCBPublisherOSType)targetType;

- (BOOL)publishEnabledForTargetType:(CCBPublisherOSType)targetType;


@end