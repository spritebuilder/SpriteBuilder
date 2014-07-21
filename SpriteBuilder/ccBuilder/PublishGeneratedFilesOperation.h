#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"
#import "CCBWarnings.h"

@class PublishRenamedFilesLookup;

@interface PublishGeneratedFilesOperation : PublishBaseOperation

@property (nonatomic) CCBPublisherOSType osType;
@property (nonatomic, copy) NSString *outputDir;
@property (nonatomic, strong) NSMutableSet *publishedSpriteSheetFiles;
@property (nonatomic, strong) PublishRenamedFilesLookup *fileLookup;

@end