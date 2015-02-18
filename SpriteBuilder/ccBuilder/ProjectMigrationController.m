#import "ProjectMigrationController.h"

#import "ResourcePathToPackageMigrator.h"
#import "ProjectMigrationViewController.h"
#import "NSError+SBErrors.h"
#import "SBErrors.h"


@implementation ProjectMigrationController

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

    return [self migrateProject:error];
}

- (BOOL)migrateProject:(NSError **)error
{
    NSMutableArray *stepsTpRollback = [NSMutableArray array];

    for (id <ProjectMigratorProtocol> migrator in _migrators)
    {
        [stepsTpRollback addObject:migrator];
        if (![migrator migrateWithError:error])
        {
            for (id <ProjectMigratorProtocol> migrationStepToRollback in stepsTpRollback)
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
    NSMutableArray *steps = [NSMutableArray array];
    for (id <ProjectMigratorProtocol> migrationStep in _migrators)
    {
        if ([migrationStep migrationRequired])
        {
            [steps addObject:[migrationStep htmlInfoText]];
        }
    }
    return [steps componentsJoinedByString:@"<br><br>"];
}

- (BOOL)needsMigration
{
    for (id <ProjectMigratorProtocol> migrationStep in _migrators)
    {
        if ([migrationStep migrationRequired])
        {
            return YES;
        }
    }
    return NO;
}

@end
