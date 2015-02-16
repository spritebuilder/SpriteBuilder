//
// Created by Nicky Weber on 11.02.15.
//

#import <Foundation/Foundation.h>

@class ProjectSettings;

@protocol ProjectMigratorProtocol <NSObject>

- (NSString *)htmlInfoText;

- (BOOL)migrationRequired;

- (BOOL)migrateWithError:(NSError **)error;

- (void)rollback;

@end
