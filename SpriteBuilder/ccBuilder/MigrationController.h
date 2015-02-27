#import <Foundation/Foundation.h>

@class ProjectSettings;
@class MigrationLogger;

@interface MigrationController : NSObject

@property (nonatomic, copy) NSArray *migrators;

@property (nonatomic, strong) MigrationLogger *logger;

- (BOOL)migrateWithError:(NSError **)error;

- (BOOL)isMigrationRequired;

@end
