#import "PackageRemover.h"

#import "SBErrors.h"
#import "PackageUtil.h"
#import "ProjectSettings.h"

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
    PackageManipulationBlock block = ^BOOL(NSString *packagePath, NSError **localError)
    {
        return [_projectSettings removeResourcePath:packagePath error:localError];
    };

    PackageUtil *packageUtil = [[PackageUtil alloc] init];
    return [packageUtil applyProjectSettingBlockForPackagePaths:packagePaths
                                                   error:error
                                     prevailingErrorCode:SBRemovePackagesError
                                        errorDescription:@"One or more packages could not be removed."
                                                   block:block];
}

@end