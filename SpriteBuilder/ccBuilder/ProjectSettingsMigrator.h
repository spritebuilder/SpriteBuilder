#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"
#import "CCEffect_Private.h"
#import "CCRendererBasicTypes_Private.h"

@class ProjectSettings;
@class BackupFileCommand;
@class MoveFileCommand;
@class MigratorData;


@interface ProjectSettingsMigrator : NSObject <MigratorProtocol>

- (instancetype)initWithMigratorData:(MigratorData *)migratorData toVersion:(NSUInteger)toVersion;

@end
