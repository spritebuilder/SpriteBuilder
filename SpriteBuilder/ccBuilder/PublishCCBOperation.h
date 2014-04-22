#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"
#import "CCBPublishDelegate.h"


@interface PublishCCBOperation : PublishBaseOperation <CCBPublishDelegate>

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *outDir;

@property (nonatomic, copy) NSString *dstFile;
@end