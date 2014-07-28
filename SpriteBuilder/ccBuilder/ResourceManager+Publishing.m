#import "ResourceManager+Publishing.h"
#import "RMPackage.h"
#import "PackagePublishSettings.h"


@implementation ResourceManager (Publishing)

- (NSArray *)loadAllPackageSettings
{
    NSMutableArray *result = [NSMutableArray array];
    for (RMDirectory *directory in self.activeDirectories)
    {
        if ([directory isKindOfClass:[RMPackage class]])
        {
            PackagePublishSettings *settings = [[PackagePublishSettings alloc] initWithPackage:(RMPackage *)directory];
            if (![settings load])
            {
                NSLog(@"Could not load Package.plist file for package \"%@\"", directory.dirPath);
            }
            [result addObject:settings];
        }
    }
    return result;
}

- (NSArray *)oldResourcePaths
{
    NSMutableArray *result = [NSMutableArray array];
    for (RMDirectory *directory in self.activeDirectories)
    {
        if ([directory isMemberOfClass:[RMDirectory class]])
        {
            [result addObject:directory];
        }
    }
    return result;
}

@end