#import <Foundation/Foundation.h>

@interface PublishOSSettings : NSObject

@property (nonatomic) BOOL resolution_tablet;
@property (nonatomic) BOOL resolution_tablethd;
@property (nonatomic) BOOL resolution_phone;
@property (nonatomic) BOOL resolution_phonehd;

@property (nonatomic) NSInteger audio_quality;

@property (nonatomic, strong) NSArray *resolutions;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
