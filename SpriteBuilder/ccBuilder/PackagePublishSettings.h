#import <Foundation/Foundation.h>
#import "CCBPublisherTypes.h"

@class RMPackage;
@class PublishOSSettings;

@interface PackagePublishSettings : NSObject

@property (nonatomic, strong) RMPackage *package;

@property (nonatomic) BOOL publishToZip;
@property (nonatomic) BOOL publishToMainProject;
@property (nonatomic) BOOL publishToCustomOutputDirectory;

// If this path  not starting with a / it will be treated as relative to the project dir
@property (nonatomic, copy) NSString *customOutputDirectory;
// Returns the default package publishing dir if publishToCustomOutputDirectory is NO, else customOutputDirectory
@property (nonatomic, copy, readonly) NSString *effectiveOutputDirectory;

@property (nonatomic) CCBPublishEnvironment publishEnvironment;

- (instancetype)initWithPackage:(RMPackage *)package;

@property (nonatomic, strong, readonly) NSDictionary *osSettings;
- (PublishOSSettings *)settingsForOsType:(CCBPublisherOSType)type;
- (void)setOSSettings:(PublishOSSettings *)osSettings forOsType:(CCBPublisherOSType)type;

- (BOOL)load;
- (BOOL)store;

@end