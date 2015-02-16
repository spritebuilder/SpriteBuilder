//
// Created by Nicky Weber on 10.02.15.
//

#import <Foundation/Foundation.h>


@interface ProjectSettingsMigrator : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)projectSettings toVersion:(NSUInteger)toVersion;

- (NSDictionary *)migrate:(NSError **)error;

@end