#import <Foundation/Foundation.h>

@class ProjectSettings;
@class CCBWarnings;
@class PublishingTaskStatusProgress;


@interface PublishBaseOperation : NSOperation
{
    __weak ProjectSettings *_projectSettings;
    __weak CCBWarnings *_warnings;
    __strong NSArray *_packageSettings;
    __strong PublishingTaskStatusProgress *_publishingTaskStatusProgress;
}

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, strong) NSArray *packageSettings;
@property (nonatomic, weak) CCBWarnings *warnings;
@property (nonatomic, strong) PublishingTaskStatusProgress *publishingTaskStatusProgress;

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings
                        packageSettings:(NSArray *)packageSettings
                               warnings:(CCBWarnings *)warnings
                         statusProgress:(PublishingTaskStatusProgress *)statusProgress;

@end