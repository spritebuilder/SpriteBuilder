#import "MigrationController.h"

#import "ResourcePathToPackageMigrator.h"
#import "MigrationViewController.h"
#import "NSError+SBErrors.h"
#import "Errors.h"


@implementation MigrationController

- (BOOL)migrateWithError:(NSError **)error
{
    if ([_migrators count] == 0)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBProjectMigrationError message:@"No migrators set up"];
        return NO;
    }

    if (![self needsMigration])
    {
        return YES;
    }

    if (![self showMigrationNeededDialogAndAskToProceed])
    {
        return NO;
    }

    if (![self migrateProject:error])
    {
        return NO;
    }

    [self tidyUp];

    return YES;
}

- (void)tidyUp
{
    for (id <MigratorProtocol> migrator in _migrators)
    {
        if ([migrator respondsToSelector:@selector(tidyUp)])
        {
            [migrator tidyUp];
        }
    }
}

- (BOOL)migrateProject:(NSError **)error
{
    NSMutableArray *stepsTpRollback = [NSMutableArray array];

    for (id <MigratorProtocol> migrator in _migrators)
    {
        [stepsTpRollback addObject:migrator];
        if (![migrator migrateWithError:error])
        {
            for (id <MigratorProtocol> migrationStepToRollback in stepsTpRollback)
            {
                [migrationStepToRollback rollback];
            }
            return NO;
        }
    }

    return YES;
}

- (BOOL)showMigrationNeededDialogAndAskToProceed
{
    if (!_delegate)
    {
        return NO;
    }
    
    return [_delegate migrateWithMigrationDetails:[self infoTextsAsHtmlOfAllMigrationSteps]];
}

- (NSString *)infoTextsAsHtmlOfAllMigrationSteps
{
    NSMutableString *result = [NSMutableString string];

    [result appendString:@"<small><ul>"];

    for (id <MigratorProtocol> migrationStep in _migrators)
    {
        if ([migrationStep migrationRequired])
        {
            [result appendString:@"<li>"];
            [result appendString:[migrationStep htmlInfoText]];
            [result appendString:@"</li>"];
        }
    }
    [result appendString:@"</ul></small>"];

    return result;
}

- (BOOL)needsMigration
{
    for (id <MigratorProtocol> migrationStep in _migrators)
    {
        if ([migrationStep migrationRequired])
        {
            return YES;
        }
    }
    return NO;
}

@end
