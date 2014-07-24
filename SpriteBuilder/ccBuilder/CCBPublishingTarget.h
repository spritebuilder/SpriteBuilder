#import <Foundation/Foundation.h>
#import "CCBWarnings.h"

@class PublishRenamedFilesLookup;


@interface CCBPublishingTarget : NSObject

@property (nonatomic, strong) NSArray *inputDirectories;
@property (nonatomic, copy) NSString *outputDirectory;
@property (nonatomic, copy) NSString *directoryToClean;
@property (nonatomic) CCBPublisherOSType osType;
@property (nonatomic, strong) NSArray *resolutions;
@property (nonatomic) CCBPublishEnvironment publishEnvironment;
@property (nonatomic) NSInteger audioQuality;

@property (nonatomic, copy) NSString *zipOutputPath;

@property (nonatomic, strong) NSMutableSet *publishedPNGFiles;
@property (nonatomic, strong) PublishRenamedFilesLookup *renamedFilesLookup;
@property (nonatomic, strong) NSMutableSet *publishedSpriteSheetFiles;

@end