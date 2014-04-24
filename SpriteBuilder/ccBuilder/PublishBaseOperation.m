#import "PublishBaseOperation.h"
#import "ProjectSettings.h"
#import "CCBWarnings.h"
#import "CCBPublisher.h"


@implementation PublishBaseOperation

- (instancetype)initWithProjectSettings:(ProjectSettings *)projectSettings warnings:(CCBWarnings *)warnings publisher:(CCBPublisher *)publisher
{
    self = [super init];
    if (self)
    {
        self.projectSettings = projectSettings;
        self.warnings = warnings;
        self.publisher = publisher;
    }

    return self;
}

@end