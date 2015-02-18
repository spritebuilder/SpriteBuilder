//
// Created by Nicky Weber on 13.02.15.
//

#import <Foundation/Foundation.h>

@protocol MigrationControllerDelegate <NSObject>

- (BOOL)migrateWithMigrationDetails:(NSString *)migrationDetails;

@end
