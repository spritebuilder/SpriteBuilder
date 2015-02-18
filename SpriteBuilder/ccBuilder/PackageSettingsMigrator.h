//
// Created by Nicky Weber on 10.02.15.
//

#import <Foundation/Foundation.h>
#import "CCRenderer_Private.h"
#import "MigratorProtocol.h"


@interface PackageSettingsMigrator : NSObject <MigratorProtocol>

- (instancetype)initWithFilepath:(NSString *)filepath toVersion:(NSUInteger)toVersion;

@end
