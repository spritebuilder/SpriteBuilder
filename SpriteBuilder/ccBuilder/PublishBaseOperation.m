#import "PublishBaseOperation.h"
#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "CCBPublisher.h"


@implementation PublishBaseOperation

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings warnings:(CCBWarnings *)warnings
{
    self = [super init];
    if (self)
    {
        self.projectSettings = projectSettings;
        self.warnings = warnings;
    }

    return self;
}

@end