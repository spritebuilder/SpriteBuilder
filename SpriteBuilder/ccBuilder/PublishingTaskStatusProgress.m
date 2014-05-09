
#import "PublishingTaskStatusProgress.h"


@implementation PublishingTaskStatusProgress

- (instancetype)initWithTaskStatus:(id <TaskStatusUpdaterProtocol>)taskStatus
{
    self = [super init];
    if (self)
    {
        self.taskStatus = taskStatus;
        self.totalTasks = 1;
    }

    return self;
}

- (void)taskFinished
{
    self.tasksFinished += 1;
    [self updateProgress];
}

- (void)updateStatusText:(NSString *)text
{
    [_taskStatus updateStatusText:text];
}

- (void)updateProgress
{
    [_taskStatus setProgress:[self currentProgress]];
}

- (double)currentProgress
{
    return MIN(1.0 / _totalTasks * _tasksFinished * 1.0, 1.0);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Tasks %lu of %lu finished: (%f.2 %%)", _tasksFinished, _totalTasks, [self currentProgress]];
}

@end