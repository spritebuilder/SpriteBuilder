#import "MigrationController.h"

#import "ResourcePathToPackageMigrator.h"
#import "NSError+SBErrors.h"
#import "Errors.h"
#import "MigrationLogger.h"


@implementation MigrationController


- (BOOL)migrateWithError:(NSError **)error
{
    if ([_migrators count] == 0)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBProjectMigrationError message:@"No migrators set up"];
        return NO;
    }

    if (![self isMigrationRequired])
    {
        return YES;
    }

    if (![self doMigrateWithError:error])
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

- (BOOL)doMigrateWithError:(NSError **)error
{
    NSMutableArray *stepsTpRollback = [NSMutableArray array];

    for (id <MigratorProtocol> migrator in _migrators)
    {
        if ([migrator respondsToSelector:@selector(setLogger:)])
        {
            [migrator setLogger:_logger];
        }

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

- (BOOL)isMigrationRequired
{
    for (id <MigratorProtocol> migrationStep in _migrators)
    {
        if ([migrationStep isMigrationRequired])
        {
            return YES;
        }
    }
    return NO;
}

@end
