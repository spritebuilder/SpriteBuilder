#import <Foundation/Foundation.h>

typedef BOOL (^FileFilterBlock)(NSURL *fileURL);


@interface NSString (Misc)

- (BOOL)isEmpty;

- (NSString *)availabeFileNameWithRollingNumberAndExtraExtension:(NSString *)extension;

// Skips hidden files
- (NSArray *)allFilesInDirWithFilterBlock:(FileFilterBlock)block;

- (NSString *)replaceExtension:(NSString *)newExtension;

@end
