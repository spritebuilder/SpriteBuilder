#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"

@class CCBWarnings;

@interface PublishSoundFileOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *srcFilePath;
@property (nonatomic, copy) NSString *dstFilePath;
@property (nonatomic) int format;
@property (nonatomic) int quality;
@property (nonatomic, copy) NSString *relativePath;

@end