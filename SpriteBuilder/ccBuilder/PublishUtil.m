#import "PublishUtil.h"
#import "ProjectSettings.h"
#import "NSString+RelativePath.h"


@implementation PublishUtil

+ (PublishDirectoryDeletionRisk)riskForPublishDirectoryBeingDeletedUponPublish:(NSString *)directory projectSettings:(ProjectSettings *)projectSettings
{
    NSAssert(projectSettings != nil, @"projectSettings must not be nil");
    NSAssert(directory  != nil, @"directory  must not be nil");

    NSString *absolutePath = [directory absolutePathFromBaseDirPath:projectSettings.projectPathDir];

    if ([projectSettings.projectPathDir rangeOfString:absolutePath].location != NSNotFound)
    {
        return PublishDirectoryDeletionRiskDirectoryContainingProject;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:absolutePath])
    {
        NSError *error;
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:absolutePath error:&error];
        if (!contents)
        {
            NSLog(@"Error reading contents at \"%@\"", absolutePath);
        }

        if (contents.count == 0)
        {
            return PublishDirectoryDeletionRiskSafe;
        }
        else
        {
            return PublishDirectoryDeletionRiskNonEmptyDirectory;
        }
    }

    return PublishDirectoryDeletionRiskSafe;
}

@end