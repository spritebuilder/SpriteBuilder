#import "ProjectSettings+Packages.h"
#import "MiscConstants.h"
#import "NSString+Packages.h"
#import "NSError+SBErrors.h"
#import "NotificationNames.h"


@implementation ProjectSettings (Packages)

- (NSString *)fullPathForPackageName:(NSString *)packageName
{
    return [self.packagesFolderPath stringByAppendingPathComponent:[packageName stringByAppendingPackageSuffix]];
}

- (BOOL)isPathInPackagesFolder:(NSString *)path
{
    NSString *packagesPathWihTrailingSlash = [self.packagesFolderPath stringByAppendingString:@"/"];
    BOOL success = [path rangeOfString:packagesPathWihTrailingSlash].location != NSNotFound;
    return success;
}

- (NSString *)packagesFolderPath
{
    return [self.projectPathDir stringByAppendingPathComponent:PACKAGES_FOLDER_NAME];
}

@end