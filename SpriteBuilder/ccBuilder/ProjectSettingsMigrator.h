#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"

@class ProjectSettings;
@class BackupFileCommand;
@class MoveFileCommand;


@interface ProjectSettingsMigrator : NSObject <MigratorProtocol>

- (id)initWithProjectFilePath:(NSString *)filePath renameResult:(NSMutableString *)renameResult;

@end
