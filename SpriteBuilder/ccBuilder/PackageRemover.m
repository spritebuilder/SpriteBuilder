#import "PackageRemover.h"

#import "SBErrors.h"
#import "PackageUtil.h"
#import "ProjectSettings.h"
#import "NotificationNames.h"

@implementation PackageRemover

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

- (BOOL)removePackagesFromProject:(NSArray *)packagePaths error:(NSError **)error
{
    PackagePathBlock block = ^BOOL(NSString *packagePath, NSError **localError)
    {
        if ([_projectSettings removeResourcePath:packagePath error:localError])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];

            return [_fileManager removeItemAtPath:packagePath error:localError];
        }

        return NO;
    };

    PackageUtil *packageUtil = [[PackageUtil alloc] init];
    return [packageUtil enumeratePackagePaths:packagePaths
                                        error:error
                          prevailingErrorCode:SBRemovePackagesError
                             errorDescription:@"One or more packages could not be removed."
                                        block:block];
}

@end