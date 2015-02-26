#import <Foundation/Foundation.h>
#import "MigratorProtocol.h"

@class ProjectSettings;


@interface ResourcePathToPackageMigrator : NSObject  <MigratorProtocol>

- (id)initWithProjectFilePath:(NSString *)filePath;

@end
