#import <Foundation/Foundation.h>

@class ProjectSettings;

@interface CCBPublisherCacheCleaner : NSObject

// Cleans(removes) the NSCachesDirectory subfolder PUBLISHER_CACHE_DIRECTORY_NAME
+ (void)cleanWithProjectSettings:(ProjectSettings *)projectSettings;

@end