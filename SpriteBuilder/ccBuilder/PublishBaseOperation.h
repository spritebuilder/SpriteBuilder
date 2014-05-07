#import <Foundation/Foundation.h>

@class ProjectSettings;
@class CCBWarnings;
@class PublishingTaskStatusProgress;


@interface PublishBaseOperation : NSOperation
{
    __weak ProjectSettings *_projectSettings;
    __weak CCBWarnings *_warnings;
    __strong PublishingTaskStatusProgress *_publishingTaskStatusProgress;
}

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) CCBWarnings *warnings;
@property (nonatomic, strong) PublishingTaskStatusProgress *publishingTaskStatusProgress;

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings warnings:(CCBWarnings *)warnings statusProgress:(PublishingTaskStatusProgress *)statusProgress;

@end