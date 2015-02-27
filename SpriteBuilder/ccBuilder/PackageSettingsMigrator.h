//
// Created by Nicky Weber on 10.02.15.
//

#import <Foundation/Foundation.h>
#import "CCRenderer_Private.h"
#import "MigratorProtocol.h"
#import "CCEffect_Private.h"

@class MigratorData;


@interface PackageSettingsMigrator : NSObject <MigratorProtocol>

- (instancetype)initWithFilepath:(NSString *)filepath toVersion:(NSUInteger)toVersion;

@end
