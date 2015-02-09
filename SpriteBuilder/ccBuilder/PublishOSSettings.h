#import <Foundation/Foundation.h>

@class PublishResolutions;

@interface PublishOSSettings : NSObject

@property (nonatomic) NSInteger audio_quality;

@property (nonatomic, strong) PublishResolutions *resolutions;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
