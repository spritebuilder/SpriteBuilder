#import <Foundation/Foundation.h>
#import "FileSystemTestCase.h"

@interface FileSystemTestCase (Images)

- (void)createPNGAtPath:(NSString *)relFilePath width:(NSUInteger)width height:(NSUInteger)height;

- (void)assertPNGAtPath:(NSString *)relFilePath hasWidth:(NSUInteger)expectedWidth hasHeight:(NSUInteger)height;

@end