//
// Created by Nicky Weber on 11.02.15.
//

#import <Foundation/Foundation.h>

@class ProjectSettings;
@class MigrationLogger;

@protocol MigratorProtocol <NSObject>

- (BOOL)isMigrationRequired;

- (BOOL)migrateWithError:(NSError **)error;

- (void)rollback;

@optional
- (void)tidyUp;

- (void)setLogger:(MigrationLogger *)migrationLogger;

@end
