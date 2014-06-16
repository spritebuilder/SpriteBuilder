#import "ProjectSettings+Packages.h"
#import "MiscConstants.h"
#import "NSString+Packages.h"
#import "NSError+SBErrors.h"
#import "NotificationNames.h"


@implementation ProjectSettings (Packages)

- (NSString *)fullPathForPackageName:(NSString *)packageName
{
    NSString *packagesFolderPath = [self.projectPathDir stringByAppendingPathComponent:PACKAGES_FOLDER_NAME];

    return [packagesFolderPath stringByAppendingPathComponent:[packageName stringByAppendingPackageSuffix]];
}

@end