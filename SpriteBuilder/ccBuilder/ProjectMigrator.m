#import "ProjectMigrator.h"

#import "PackageMigrator.h"
#import "ProjectSettings.h"
#import "NSAlert+Convenience.h"


@interface ProjectMigrator ()

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, strong) PackageMigrator *packageMigrator;

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
    if (!_packageMigrator)
    {
        self.packageMigrator = [[PackageMigrator  alloc] initWithProjectSettings:_projectSettings];
    }

    NSError *error;
    if (![_packageMigrator migrate:&error])
    {
        [_packageMigrator rollback];

        [NSAlert showModalDialogWithTitle:@"Error migrating" htmlBodyText:error.localizedDescription];

        return NO;
    }

    return YES;
}

- (void)rollback
{
    [_packageMigrator rollback];
}

@end