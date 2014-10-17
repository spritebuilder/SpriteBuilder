#import <Foundation/Foundation.h>

@class ProjectSettings;


typedef enum {
    PublishDirectoryDeletionRiskSafe = 0,
    PublishDirectoryDeletionRiskNonEmptyDirectory,
    PublishDirectoryDeletionRiskDirectoryContainingProject
} PublishDirectoryDeletionRisk;



@interface PublishUtil : NSObject
{

}

+ (PublishDirectoryDeletionRisk)riskForPublishDirectoryBeingDeletedUponPublish:(NSString *)directory projectSettings:(ProjectSettings *)projectSettings;


@end