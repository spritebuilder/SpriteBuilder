//
// Created by Nicky Weber on 21.01.15.
//

#import <Foundation/Foundation.h>


@interface CCBDictionaryMigrator : NSObject

@property (nonatomic, readonly) NSDictionary *ccb;

// Default is kCCBDictionaryFormatVersion but can be set to any value if needed
@property (nonatomic) NSUInteger ccbMigrationVersionTarget;

// Default is CCBDictionaryMigrationStepVersion
@property (nonatomic, copy) NSString *migrationStepClassPrefix;

- (instancetype)initWithCCB:(NSDictionary *)ccb;

- (NSDictionary *)migrate:(NSError **)error;

@end
