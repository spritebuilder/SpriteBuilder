#import <Foundation/Foundation.h>

@class ProjectSettings;
@class MigrationViewController;
@protocol MigrationControllerDelegate;
@class MigrationLogger;

@interface MigrationController : NSObject

// If nil the migration will proceed
@property (nonatomic, weak) id <MigrationControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *migrators;

@property (nonatomic, strong) MigrationLogger *logger;

- (BOOL)migrateWithError:(NSError **)error;

@end
