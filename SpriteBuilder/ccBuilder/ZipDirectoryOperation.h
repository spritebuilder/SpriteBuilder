#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"

@interface ZipDirectoryOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *inputPath;
@property (nonatomic, copy) NSString *zipOutputPath;

@property (nonatomic) int compression;

@end