#import <Foundation/Foundation.h>

@interface PublishOSSettings : NSObject

@property (nonatomic) BOOL resolution_1x;
@property (nonatomic) BOOL resolution_2x;
@property (nonatomic) BOOL resolution_4x;

@property (nonatomic) NSInteger audio_quality;

@property (nonatomic, strong) NSArray *resolutions;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
