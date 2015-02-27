#import "PackageImporter.h"

#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"
#import "NSString+Packages.h"
#import "Errors.h"
#import "PackageUtil.h"
#import "NotificationNames.h"
#import "NSError+SBErrors.h"
#import "MiscConstants.h"
#import "RMPackage.h"
#import "PackageSettings.h"
#import "PackageSettingsMigrator.h"
#import "MigrationController.h"
#import "CCBToSBRenameMigrator.h"
#import "AllPackageSettingsMigrator.h"
#import "AllDocumentsMigrator.h"
#import "CCBDictionaryReader.h"

@implementation PackageImporter

- (id)init
{
    self = [super init];
    if (self)
    {
        // default until we get some injection framework running
        self.fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (BOOL)importPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPath = [_projectSettings fullPathForPackageName:packageName];

    return [self importPackagesWithPaths:@[fullPath] error:nil];
}

- (NSArray *)allPackagesInPaths:(NSArray *)paths
{
    if (!paths)
    {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray array];
    for (NSString *path in paths)
    {
        if ([path hasPackageSuffix])
        {
            RMPackage *aPackage = [[RMPackage alloc] init];
            aPackage.dirPath = path;

            [result addObject:aPackage];
        }
    }
    return result;
}

- (BOOL)importPackagesWithPaths:(NSArray *)packagePaths error:(NSError **)error
{
    if (!packagePaths || packagePaths.count == 0)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBNoPackagePathsToImport message:[NSString stringWithFormat:@"No paths to import given"]];
        return NO;
    }

    NSArray *filteredPaths = [self allPackagesInPaths:packagePaths];
    if (filteredPaths.count == 0)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBPathWithoutPackageSuffix message:[NSString stringWithFormat:@"No paths to import given with .%@ suffix", PACKAGE_NAME_SUFFIX]];
        return NO;
    }

    PackagePathBlock block = [self packagePathImportBlock];

    PackageUtil *packageUtil = [[PackageUtil alloc] init];
    return [packageUtil enumeratePackages:filteredPaths
                                    error:error
                      prevailingErrorCode:SBImportingPackagesError
                         errorDescription:@"One or more packages could not be imported."
                                    block:block];
}

- (PackagePathBlock)packagePathImportBlock
{
    return ^BOOL(RMPackage *packageToImport, NSError **localError)
    {
        if ([_projectSettings isPackageWithFullPathInProject:packageToImport.dirPath])
        {
            [NSError setNewErrorWithErrorPointer:localError code:SBPackageAlreayInProject message:@"Package already in project folder."];
            return NO;
        }

        NSString *packageName = [[packageToImport.dirPath lastPathComponent] stringByDeletingPathExtension];
        NSString *newPathInPackagesFolder = [_projectSettings fullPathForPackageName:packageName];

        if (![_projectSettings isPathInPackagesFolder:packageToImport.dirPath]
            && ![_fileManager copyItemAtPath:packageToImport.dirPath toPath:newPathInPackagesFolder error:localError])
        {
            return NO;
        }

        if (![_projectSettings addPackageWithFullPath:newPathInPackagesFolder error:localError])
        {
            return NO;
        }

        MigrationController *migrationController = [[MigrationController alloc] init];
        migrationController.migrators = @[
            [[AllDocumentsMigrator alloc] initWithDirPath:newPathInPackagesFolder toVersion:kCCBDictionaryFormatVersion],
            [[AllPackageSettingsMigrator alloc] initWithPackagePaths:@[newPathInPackagesFolder] toVersion:PACKAGE_SETTINGS_VERSION],
            [[CCBToSBRenameMigrator alloc] initWithFilePath:newPathInPackagesFolder migratorData:nil]];

        if (![migrationController migrateWithError:localError])
        {
            return NO;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:self];
        return YES;
    };
}

@end
