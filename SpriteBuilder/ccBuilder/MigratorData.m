#import "MigratorData.h"


@implementation MigratorData

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.renamedFiles = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (instancetype)initWithProjectSettingsPath:(NSString *)projectSettingsPath
{
    NSAssert(projectSettingsPath != nil, @"projectSettingsPath must not be nil");

    MigratorData *result = [self init];

    result.projectSettingsPath = projectSettingsPath;
    result.originalProjectSettingsPath = projectSettingsPath;

    return result;
}

- (NSString *)projectPath
{
    return [_projectSettingsPath stringByDeletingLastPathComponent];
}

@end
