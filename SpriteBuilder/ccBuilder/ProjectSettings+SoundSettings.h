#import <Foundation/Foundation.h>
#import "ProjectSettings.h"

@interface ProjectSettings (SoundSettings)

- (int)soundQualityForRelPath:(NSString *)relPath targetType:(int)targetType;
- (int)soundFormatForRelPath:(NSString *)relPath targetType:(int)targetType;

@end