#import "CCBPublisherCacheCleaner.h"
#import "ProjectSettings.h"
#import "MiscConstants.h"


@implementation CCBPublisherCacheCleaner

+ (void)cleanWithProjectSettings:(ProjectSettings *)projectSettings
{
    projectSettings.needRepublish = YES;
    [projectSettings store];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* ccbChacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:PUBLISHER_CACHE_DIRECTORY_NAME];
    [[NSFileManager defaultManager] removeItemAtPath:ccbChacheDir error:NULL];
}

@end