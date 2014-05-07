#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"

@class CCBWarnings;
@class FCFormatConverter;
@class PublishRenamedFilesLookup;

@interface PublishSoundFileOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *srcFilePath;
@property (nonatomic, copy) NSString *dstFilePath;
@property (nonatomic) int format;
@property (nonatomic) int quality;
@property (nonatomic, strong) PublishRenamedFilesLookup *fileLookup;

@end