#import "Cocos2dUpdater.h"

@interface Cocos2dUpdater (Errors)

- (NSError *)errorForFailedUnzipTask:(NSString *)zipFile dataStdOut:(NSData *)dataStdOut dataStdErr:(NSData *)dataStdErr status:(int)status;
- (NSError *)errorForUnzipTaskWithException:(NSException *)exception zipFile:(NSString *)zipFile;
- (NSError *)errorForNonExistentTemplateFile:(NSString *)zipFile;

@end