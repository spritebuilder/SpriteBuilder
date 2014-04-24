#import <Foundation/Foundation.h>

@class ProjectSettings;
@class CCBWarnings;
@class CCBPublisher;


@interface PublishBaseOperation : NSOperation
{
    ProjectSettings *_projectSettings;
    CCBWarnings *_warnings;
}

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) CCBWarnings *warnings;

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings warnings:(CCBWarnings *)warnings;

@end