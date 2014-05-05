#import <Foundation/Foundation.h>

@interface NSString (Publishing)

// File methods
- (BOOL)isResourceAutoFile;
- (BOOL)isSoundFile;
- (BOOL)isSmartSpriteSheetCompatibleFile;

// Directoy methods
- (NSString *)resourceAutoFilePath;
- (NSDate *)latestModifiedDateOfPath;
- (NSArray *)allPNGFilesInPath;

@end