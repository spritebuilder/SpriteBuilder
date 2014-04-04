#import "Cocos2dUpater.h"

@interface Cocos2dUpater (Errors)

- (NSError *)errorForFailedUnzipTask:(NSString *)zipFile dataStdOut:(NSData *)dataStdOut dataStdErr:(NSData *)dataStdErr status:(int)status;
- (NSError *)errorForUnzipTaskWithException:(NSException *)exception zipFile:(NSString *)zipFile;
- (NSError *)errorForNonExistentTemplateFile:(NSString *)zipFile;

@end