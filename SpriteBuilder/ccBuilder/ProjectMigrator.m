#import "ProjectMigrator.h"

#import "ProjectSettings.h"
#import "PackageMigrationController.h"
#import "ResourcePropertiesMigrator.h"


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
    BOOL result = YES;

    PackageMigrationController *packageMigrationController = [[PackageMigrationController alloc] initWithProjectSettings:_projectSettings];

    ResourcePropertiesMigrator *resourcePropertiesMigrator = [[ResourcePropertiesMigrator alloc] initWithProjectSettings:_projectSettings];

    result = result && [packageMigrationController migrate];
    result = result && [resourcePropertiesMigrator migrate];

    return result;
}

@end