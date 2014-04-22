#import <Foundation/Foundation.h>

@class ProjectSettings;
@class CCBWarnings;
@class CCBPublisher;


@interface PublishBaseOperation : NSOperation
{
    ProjectSettings *_projectSettings;
    CCBWarnings *_warnings;
    __weak CCBPublisher *_publisher;
}

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) CCBWarnings *warnings;

// TODO: exchange with publisherDelegate interface
@property (nonatomic, weak) CCBPublisher *publisher;

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings warnings:(CCBWarnings *)warnings;

@end