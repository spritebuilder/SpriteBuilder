#import "ProjectMigrator.h"

#import "ProjectSettings.h"
#import "PackageMigrationController.h"


@interface ProjectMigrator ()

@property (nonatomic, weak) ProjectSettings *projectSettings;

@end


@implementation ProjectMigrator

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    self = [super init];
    if (self)
    {
        self.projectSettings = projectSettings;
    }

    return self;
}

- (BOOL)migrate
{
    PackageMigrationController *packageMigrationController = [[PackageMigrationController alloc] initWithProjectSettings:_projectSettings];
    return [packageMigrationController migrate];
}

@end