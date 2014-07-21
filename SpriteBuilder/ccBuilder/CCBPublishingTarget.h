#import <Foundation/Foundation.h>
#import "CCBWarnings.h"


@interface CCBPublishingTarget : NSObject

@property (nonatomic, strong) NSArray *inputDirectories;
@property (nonatomic, copy) NSString *outputDirectory;
@property (nonatomic) CCBPublisherOSType osType;
@property (nonatomic, strong) NSArray *resolutions;

@end