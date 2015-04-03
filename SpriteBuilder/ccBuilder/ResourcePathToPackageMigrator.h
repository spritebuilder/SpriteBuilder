#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"

@class ProjectSettings;
@class MigratorData;


@interface ResourcePathToPackageMigrator : NSObject  <MigratorProtocol>

- (id)initWithMigratorData:(MigratorData *)migratorData;

@end
