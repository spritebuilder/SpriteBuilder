#import <Foundation/Foundation.h>

@class ProjectSettings;
@class ProjectMigrationViewController;
@protocol ProjectMigrationControllerDelegate;

@interface ProjectMigrationController : NSObject

@property (nonatomic, weak) id <ProjectMigrationControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *migrators;

- (BOOL)migrateWithError:(NSError **)error;

@end
