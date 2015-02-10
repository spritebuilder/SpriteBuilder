//
// Created by Nicky Weber on 10.02.15.
//

#import <Foundation/Foundation.h>
#import "CCRenderer_Private.h"


@interface SBPackageSettingsMigrator : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)packageSettings toVersion:(NSUInteger)toVersion;

- (NSDictionary *)migrate:(NSError **)error;

@end
