#import <Foundation/Foundation.h>

@class ProjectSettings;
@class CCBWarnings;
@class CCBPublisher;


@interface PublishBaseOperation : NSOperation
{
    __weak ProjectSettings *_projectSettings;
    __weak CCBWarnings *_warnings;
    __weak CCBPublisher *_publisher;
}

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) CCBWarnings *warnings;
@property (nonatomic, weak) CCBPublisher *publisher;

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings warnings:(CCBWarnings *)warnings publisher:(CCBPublisher *)publisher;

@end