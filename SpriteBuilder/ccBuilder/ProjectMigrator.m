#import <MacTypes.h>
#import "ProjectMigrator.h"
#import "PackageMigrator.h"
#import "ProjectSettings.h"
#import "NSAlert+Convenience.h"


@interface ProjectMigrator ()

@property (nonatomic, weak)ProjectSettings *projectSettings;

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

- (void)migrate
{
    PackageMigrator *packageMigrator = [[PackageMigrator  alloc] initWithProjectSettings:_projectSettings];

    NSError *error;
    if (![packageMigrator migrate:&error])
    {
        [NSAlert showModalDialogWithTitle:@"Error migrating" message:error.localizedDescription];
    }
}

@end