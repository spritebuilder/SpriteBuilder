//
// Created by Nicky Weber on 16.02.15.
//

#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"


@interface AllPackageSettingsMigrator : NSObject <MigratorProtocol>

- (id)initWithProjectSettings:(ProjectSettings *)projectSettings;

@end
