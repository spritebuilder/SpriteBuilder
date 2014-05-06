#import "PublishBaseOperation.h"

#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "PublishingTaskStatusProgress.h"


@implementation PublishBaseOperation

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings warnings:(CCBWarnings *)warnings statusProgress:(PublishingTaskStatusProgress *)statusProgress
{
    self = [super init];

    if (self)
    {
        self.projectSettings = projectSettings;
        self.warnings = warnings;
        self.publishingTaskStatusProgress = statusProgress;
    }

    return self;
}

@end