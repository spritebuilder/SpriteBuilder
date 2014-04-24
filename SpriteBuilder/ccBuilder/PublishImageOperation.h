#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"

@class DateCache;
@class CCBPublisher;

@interface PublishImageOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *srcPath;
@property (nonatomic, copy) NSString *dstPath;
@property (nonatomic, copy) NSString *outDir;
@property (nonatomic, copy) NSString *resolution;

@property (nonatomic, weak) NSMutableSet *publishedResources;
@property (nonatomic, weak) NSMutableSet *publishedPNGFiles;

// TODO: not ideal, rename rules
@property (nonatomic, weak) CCBPublisher *publisher;

@property (nonatomic) BOOL isSpriteSheet;
@property (nonatomic) int targetType;


@property (nonatomic, strong) DateCache *modifiedFileDateCache;

@end