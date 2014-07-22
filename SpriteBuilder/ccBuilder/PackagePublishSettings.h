#import <Foundation/Foundation.h>
#import "CCBPublisherTypes.h"

@class RMPackage;
@class PublishOSSettings;

@interface PackagePublishSettings : NSObject

@property (nonatomic, weak) RMPackage *package;
@property (nonatomic, copy) NSString *outputDirectory;
@property (nonatomic) CCBPublishEnvironment publishEnvironment;

- (instancetype)initWithPackage:(RMPackage *)package;

@property (nonatomic, strong, readonly) NSDictionary *osSettings;
- (PublishOSSettings *)settingsForOsType:(CCBPublisherOSType)type;
- (void)setOSSettings:(PublishOSSettings *)osSettings forOsType:(CCBPublisherOSType)type;

@end