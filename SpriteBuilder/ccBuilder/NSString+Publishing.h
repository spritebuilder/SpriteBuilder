#import <Foundation/Foundation.h>

@interface NSString (Publishing)

- (NSString *)resourceAutoFilePath;
- (BOOL)isResourceAutoFile;

- (BOOL)isSoundFile;
- (BOOL)isSmartSpriteSheetCompatibleFile;

- (NSDate *)latestModifiedDateForDirectory;

@end