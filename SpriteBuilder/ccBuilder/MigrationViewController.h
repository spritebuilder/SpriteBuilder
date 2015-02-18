//
// Created by Nicky Weber on 13.02.15.
//

#import <Foundation/Foundation.h>
#import "MigrationControllerDelegate.h"

@class ProjectSettings;
@class MigrationController;


@interface MigrationViewController : NSObject <MigrationControllerDelegate>

// Default is Migration
@property (nonatomic, copy) NSString *dialogTitle;
// Default is Cancel
@property (nonatomic, copy) NSString *cancelButtonTitle;

- (instancetype)initWithMigrationController:(MigrationController *)migrationController;

- (BOOL)migrate;

@end