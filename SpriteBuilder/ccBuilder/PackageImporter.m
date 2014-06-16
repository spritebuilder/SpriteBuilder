#import "PackageImporter.h"
#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"
#import "NSString+Packages.h"
#import "SBErrors.h"
#import "PackageUtil.h"

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
            [result addObject:path];
        }
    }
    return result;
}

- (BOOL)importPackagesWithPaths:(NSArray *)packagePaths error:(NSError **)error
{
    NSArray *filteredPaths = [self allPackagesInPaths:packagePaths];

    PackageManipulationBlock block = ^BOOL(NSString *packagePath, NSError **localError)
    {
        return [_projectSettings addResourcePath:packagePath error:localError];
    };

    PackageUtil *packageUtil = [[PackageUtil alloc] init];
    return [packageUtil applyProjectSettingBlockForPackagePaths:filteredPaths
                                                   error:error
                                     prevailingErrorCode:SBImportingPackagesError
                                        errorDescription:@"One or more packages could not be imported."
                                                   block:block];
}

@end