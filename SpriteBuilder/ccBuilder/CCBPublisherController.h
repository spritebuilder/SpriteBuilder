#import <Foundation/Foundation.h>
#import "CCBDirectoryPublisher.h"

@class ProjectSettings;
@class CCBWarnings;

@interface CCBPublisherController : NSObject

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, strong) NSArray *packageSettings;
@property (nonatomic, strong) NSArray *oldResourcePaths;
@property (nonatomic, weak) id<TaskStatusUpdaterProtocol> taskStatusUpdater;
@property (nonatomic, copy) PublisherFinishBlock finishBlock;

@property (nonatomic, strong, readonly) CCBWarnings *warnings;

- (void)startAsync:(BOOL)async;
- (void)cancel;

@end