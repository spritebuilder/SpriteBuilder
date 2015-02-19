//
// Created by Nicky Weber on 21.01.15.
//

#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"

@class ProjectSettings;


@interface CCBDictionaryMigrator : NSObject <MigratorProtocol>

// Default is CCBDictionaryMigrationStepVersion
@property (nonatomic, copy) NSString *migrationStepClassPrefix;

- (id)initWithFilepath:(NSString *)filepath toVersion:(NSUInteger)toVersion;

@end
