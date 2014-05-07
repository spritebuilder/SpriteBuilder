#import "PublishBaseOperation.h"

#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "PublishingTaskStatusProgress.h"
#import "PublishLogging.h"


@implementation PublishBaseOperation

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings warnings:(CCBWarnings *)warnings statusProgress:(PublishingTaskStatusProgress *)statusProgress
{
    NSAssert(projectSettings != nil, @"projectSettings should not be nil");
    NSAssert(warnings != nil, @"warnings should not be nil");

    self = [super init];

    if (self)
    {
        self.projectSettings = projectSettings;
        self.warnings = warnings;
        self.publishingTaskStatusProgress = statusProgress;
    }

    return self;
}

- (void)main
{
    LocalLog(@"[%@] STARTED %@", [self class], [self description]);
}

- (void)cancel
{
    LocalLog(@"[%@] CANCELLED %@", [self class], [self description]);
    [super cancel];
}

@end