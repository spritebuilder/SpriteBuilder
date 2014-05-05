#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"
#import "CCBWarnings.h"

@class DateCache;
@class CCBPublisher;
@class FCFormatConverter;
@class PublishFileLookup;

@interface PublishImageOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *srcPath;
@property (nonatomic, copy) NSString *dstPath;
@property (nonatomic, copy) NSString *outDir;
@property (nonatomic, copy) NSString *resolution;

@property (nonatomic, strong) NSMutableSet *publishedResources;
@property (nonatomic, strong) NSMutableSet *publishedPNGFiles;
@property (nonatomic, strong) PublishFileLookup *fileLookup;

@property (nonatomic) BOOL isSpriteSheet;
@property (nonatomic) CCBPublisherTargetType targetType;

@property (nonatomic, strong) DateCache *modifiedFileDateCache;

@end