#import <Foundation/Foundation.h>
#import "CCBWarnings.h"


@interface CCBPublishingTarget : NSObject

@property (nonatomic) CCBPublisherTargetType platform;

@property (nonatomic, copy) NSString *outputDirectory;
@property (nonatomic, copy) NSString *inputDirectory;

@property (nonatomic, strong) NSArray *resolutions;
@property (nonatomic, strong) NSArray *inputDirectories;

@property (nonatomic, copy) NSString *resolution;

@end