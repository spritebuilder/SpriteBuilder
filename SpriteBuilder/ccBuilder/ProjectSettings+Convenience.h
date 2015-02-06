#import <Foundation/Foundation.h>

#import "ProjectSettings.h"
#import "CCBWarnings.h"

@interface ProjectSettings (Convenience)

- (NSInteger)soundQualityForRelPath:(NSString *)relPath osType:(CCBPublisherOSType)osType;
- (int)soundFormatForRelPath:(NSString *)relPath osType:(CCBPublisherOSType)osType;

- (NSString *)publishDirForOSType:(CCBPublisherOSType)osType;

@end
