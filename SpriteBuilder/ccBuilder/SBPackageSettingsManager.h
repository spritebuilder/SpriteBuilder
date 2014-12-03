#import <Foundation/Foundation.h>

@class SBPackageSettings;
@class RMPackage;
@class ResourceManager;


@interface SBPackageSettingsManager : NSObject

@property (nonatomic, weak) ResourceManager *resourceManager;

+ (SBPackageSettingsManager *)sharedManager;

- (NSArray *)allPackageSettings;

- (SBPackageSettings *)packageSettingsForPackage:(RMPackage *)package;

// Creates and returns a new package settings object. Package settings will be added to manager and saved to disk immediately
- (SBPackageSettings *)createPackageSettingsWithPackage:(RMPackage *)package;

- (void)addPackageSettings:(SBPackageSettings *)packageSettings;

- (void)removePackageSettings:(SBPackageSettings *)packageSettings;

- (void)loadAllPackageSettings;

- (void)saveAllPackageSettings;

@end
