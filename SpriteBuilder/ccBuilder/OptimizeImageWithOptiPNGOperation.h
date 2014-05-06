#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"

@interface OptimizeImageWithOptiPNGOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *optiPngPath;
@property (nonatomic, strong) NSTask *task;

@end