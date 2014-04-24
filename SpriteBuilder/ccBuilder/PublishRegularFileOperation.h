#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"


@interface PublishRegularFileOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *srcFilePath;
@property (nonatomic, copy) NSString *dstFilePath;

@end