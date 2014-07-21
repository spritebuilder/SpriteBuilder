#import <Foundation/Foundation.h>
#import "CCBPublisherTypes.h"

@class RMPackage;

@interface PackageSettings : NSObject

@property (nonatomic, weak) RMPackage *package;
@property (nonatomic, copy) NSString *outputDirectory;
@property (nonatomic) CCBPublishEnvironment publishEnvironment;

- (instancetype)initWithPackage:(RMPackage *)package;

- (BOOL)isPublishEnabledForOSType:(CCBPublisherOSType)osType;
- (void)setPublishEnabled:(BOOL)enabled forOSType:(CCBPublisherOSType)osType;

- (NSArray *)publishResolutionsForOSType:(CCBPublisherOSType)osType;
- (void)setPublishResolutions:(NSArray *)resolutions forOSType:(CCBPublisherOSType)osType;

@end