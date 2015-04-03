#import "PackageRemover.h"

#import "Errors.h"
#import "PackageUtil.h"
#import "ProjectSettings.h"
#import "NotificationNames.h"
#import "RMPackage.h"
#import "MiscConstants.h"

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

- (BOOL)removePackagesFromProject:(NSArray *)packages error:(NSError **)error
{
    PackagePathBlock block = ^BOOL(RMPackage *package, NSError **localError)
    {
        if ([_projectSettings removePackageWithFullPath:package.dirPath error:localError])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATH_REMOVED
                                                                object:self
                                                              userInfo:@{NOTIFICATION_USERINFO_KEY_FILEPATH : package.dirPath, NOTIFICATION_USERINFO_KEY_RESOURCE : package}];

            [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:self];

            return [_fileManager removeItemAtPath:package.dirPath error:localError];
        }

        return NO;
    };

    PackageUtil *packageUtil = [[PackageUtil alloc] init];
    return [packageUtil enumeratePackages:packages
                                    error:error
                      prevailingErrorCode:SBRemovePackagesError
                         errorDescription:@"One or more packages could not be removed."
                                    block:block];
}

@end