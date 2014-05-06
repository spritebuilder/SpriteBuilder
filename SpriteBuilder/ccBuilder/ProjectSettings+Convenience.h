#import <Foundation/Foundation.h>

#import "ProjectSettings.h"
#import "CCBWarnings.h"

@interface ProjectSettings (Convenience)

- (BOOL)isPublishEnvironmentRelease;
- (BOOL)isPublishEnvironmentDebug;

- (int)soundQualityForRelPath:(NSString *)relPath targetType:(CCBPublisherTargetType)targetType;
- (int)soundFormatForRelPath:(NSString *)relPath targetType:(CCBPublisherTargetType)targetType;

- (NSArray *)publishingResolutionsForTargetType:(CCBPublisherTargetType)targetType;

- (NSString *)publishDirForTargetType:(CCBPublisherTargetType)targetType;

- (BOOL)publishEnabledForTargetType:(CCBPublisherTargetType)targetType;


@end