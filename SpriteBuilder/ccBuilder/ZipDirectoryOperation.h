#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"

@interface ZipDirectoryOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *inputPath;
@property (nonatomic, copy) NSString *zipOutputPath;
@property (nonatomic) NSUInteger compression;
@property (nonatomic) BOOL createDirectories;

@end