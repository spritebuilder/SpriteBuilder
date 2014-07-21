#import <Foundation/Foundation.h>
#import "CCBPublisherTypes.h"

@class RMPackage;

@interface PackageSettings : NSObject

@property (nonatomic, weak) RMPackage *package;
@property (nonatomic, copy) NSString *outputDirectory;
@property (nonatomic, copy) NSArray *resolutions;
@property (nonatomic) CCBPublishEnvironment publishEnvironment;

- (instancetype)initWithPackage:(RMPackage *)package;

- (BOOL)isPublishEnabledForOSType:(CCBPublisherOSType)osType;
- (void)setPublishEnabled:(BOOL)enabled forOSType:(CCBPublisherOSType)osType;

@end