#import <Foundation/Foundation.h>
#import "TaskStatusUpdaterProtocol.h"


@interface PublishingTaskStatusProgress : NSObject

@property (nonatomic, strong) id<TaskStatusUpdaterProtocol> taskStatus;
@property (nonatomic) NSUInteger tasksFinished;
@property (nonatomic) NSUInteger totalTasks;

- (instancetype)initWithTaskStatus:(id <TaskStatusUpdaterProtocol>)taskStatus;

- (void)taskFinished;

- (void)updateStatusText:(NSString *)text;

@end