#import <Foundation/Foundation.h>
#import "CCBPublisherTypes.h"


extern NSInteger const DEFAULT_TAG_VALUE_GLOBAL_DEFAULT_SCALING;

@class RMPackage;
@class PublishOSSettings;

@interface SBPackageSettings : NSObject

@property (nonatomic, strong) RMPackage *package;

@property (nonatomic) BOOL publishToZip;
@property (nonatomic) BOOL publishToMainProject;
@property (nonatomic) BOOL publishToCustomOutputDirectory;

@property (nonatomic) BOOL mainProject_resolution_1x;
@property (nonatomic) BOOL mainProject_resolution_2x;
@property (nonatomic) BOOL mainProject_resolution_4x;

// If this path  not starting with a / it will be treated as relative to the project dir
@property (nonatomic, copy) NSString *customOutputDirectory;
// Returns the default package publishing dir if publishToCustomOutputDirectory is NO, else customOutputDirectory
@property (nonatomic, copy, readonly) NSString *effectiveOutputDirectory;

@property (nonatomic) CCBPublishEnvironment publishEnvironment;

@property (nonatomic) NSInteger resourceAutoScaleFactor;

@property (nonatomic, strong, readonly) NSDictionary *osSettings;

- (instancetype)initWithPackage:(RMPackage *)package;

- (PublishOSSettings *)settingsForOsType:(CCBPublisherOSType)type;

- (void)setOSSettings:(PublishOSSettings *)osSettings forOsType:(CCBPublisherOSType)type;

- (BOOL)load;
- (BOOL)store;

- (NSArray *)mainProjectResolutions;

@end