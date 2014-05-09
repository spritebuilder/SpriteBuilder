#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"
#import "CCBWarnings.h"

@class PublishRenamedFilesLookup;

@interface PublishGeneratedFilesOperation : PublishBaseOperation

@property (nonatomic) CCBPublisherTargetType targetType;
@property (nonatomic, copy) NSString *outputDir;
@property (nonatomic, strong) NSMutableSet *publishedSpriteSheetFiles;
@property (nonatomic, strong) PublishRenamedFilesLookup *fileLookup;

@end