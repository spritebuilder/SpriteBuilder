#import <MacTypes.h>
#import "PackageMigrationController.h"
#import "PackageMigrator.h"
#import "ProjectSettings.h"
#import "NSAlert+Convenience.h"

typedef enum
{
    MigrationActionNothingToDo = 0,
    MigrationActionMigrate,
    MigrationActionDontAskAgain,
} MigrationAction;


@interface PackageMigrationController ()

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, strong) PackageMigrator *packageMigrator;

@end


@implementation PackageMigrationController

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"ProjectSettings must be set");

    self = [super init];
    if (self)
    {
        self.projectSettings = projectSettings;
        self.packageMigrator = [[PackageMigrator alloc] initWithProjectSettings:projectSettings];
    }

    return self;
}

- (BOOL)migrate
{
    if (_projectSettings.excludedFromPackageMigration
        || ![_packageMigrator needsMigration])
    {
        return YES;
    }

    MigrationAction action = [self showPreMigrationDialog];

    if (action == MigrationActionNothingToDo)
    {
        return YES;
    }

    if (action == MigrationActionDontAskAgain)
    {
        _projectSettings.excludedFromPackageMigration = YES;
        return YES;
    }

    return [self tryToMigrate];
}

- (BOOL)tryToMigrate
{
    NSError *error;
    if (![_packageMigrator migrate:&error])
    {
        [_packageMigrator rollback];

        [NSAlert showModalDialogWithTitle:@"Error migrating" htmlBodyText:error.localizedDescription];

        return NO;
    }

    return YES;
}

- (MigrationAction)showPreMigrationDialog
{
    NSString *LINK_FORUM_PACKAGE_INSTRUCTIONS = @"http://spritebuilder.com";

    NSString *htmlText = [NSString stringWithFormat:@
            "To introduce a newer feature called <b>packages</b> we'd like to migrate your project to a newer format. "
            "<br/><br/><b>This migration is optional.</b><br/><br/> You can read more about packages on the <a href='%@'>forums</a>. "
            "If you like to migrate later on but don't want to see this dialog again you can find instructions on how to reset the dialog on the forums too.",
            LINK_FORUM_PACKAGE_INSTRUCTIONS];

    NSAlert *alert = [NSAlert alertWithTitle:@"Package Migration" htmlBodyText:htmlText];
    // beware: return value is depending on the position of the button
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert addButtonWithTitle:@"No, don't ask again"];

    NSInteger returnValue = [alert runModal];
    switch (returnValue)
    {
        case NSAlertFirstButtonReturn: return MigrationActionMigrate;
        case NSAlertSecondButtonReturn: return MigrationActionNothingToDo;
        case NSAlertThirdButtonReturn: return MigrationActionDontAskAgain;
        default: return MigrationActionNothingToDo;
    }
}

@end