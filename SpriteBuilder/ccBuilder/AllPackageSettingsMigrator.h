//
// Created by Nicky Weber on 16.02.15.
//

#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"
#import "CCEffect_Private.h"

@class MigratorData;


@interface AllPackageSettingsMigrator : NSObject <MigratorProtocol>

- (instancetype)initWithMigratorData:(MigratorData *)migratorData toVersion:(NSUInteger)toVersion;

- (instancetype)initWithPackagePaths:(NSArray *)packagePaths toVersion:(NSUInteger)toVersion;

@end
