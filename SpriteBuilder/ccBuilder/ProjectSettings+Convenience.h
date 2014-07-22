#import <Foundation/Foundation.h>

#import "ProjectSettings.h"
#import "CCBWarnings.h"

@interface ProjectSettings (Convenience)

- (BOOL)isPublishEnvironmentRelease;
- (BOOL)isPublishEnvironmentDebug;

- (NSInteger)soundQualityForRelPath:(NSString *)relPath osType:(CCBPublisherOSType)osType;
- (int)soundFormatForRelPath:(NSString *)relPath osType:(CCBPublisherOSType)osType;

- (NSArray *)publishingResolutionsForOSType:(CCBPublisherOSType)osType;

- (NSString *)publishDirForOSType:(CCBPublisherOSType)osType;

- (BOOL)publishEnabledForOSType:(CCBPublisherOSType)osType;


- (NSInteger)audioQualityForOsType:(CCBPublisherOSType)osType;
@end