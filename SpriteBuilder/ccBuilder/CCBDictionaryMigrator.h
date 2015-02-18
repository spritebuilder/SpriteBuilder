//
// Created by Nicky Weber on 21.01.15.
//

#import <Foundation/Foundation.h>


@interface CCBDictionaryMigrator : NSObject

@property (nonatomic, readonly) NSDictionary *ccb;

// Default is CCBDictionaryMigrationStepVersion
@property (nonatomic, copy) NSString *migrationStepClassPrefix;

- (instancetype)initWithCCB:(NSDictionary *)ccb toVersion:(NSUInteger)toVersion;

- (NSDictionary *)migrate:(NSError **)error;

@end
