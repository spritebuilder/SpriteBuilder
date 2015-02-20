#import <Foundation/Foundation.h>

@class ProjectSettings;
@class MigrationViewController;
@protocol MigrationControllerDelegate;

@interface MigrationController : NSObject

// If nil the migration will proceed
@property (nonatomic, weak) id <MigrationControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *migrators;

- (BOOL)migrateWithError:(NSError **)error;

@end
