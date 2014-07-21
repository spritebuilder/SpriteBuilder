#import <Foundation/Foundation.h>
#import "CCBPublisherTypes.h"
#import "CCBWarnings.h"

@class ProjectSettings;
@protocol TaskStatusUpdaterProtocol;
@class CCBPublishingTarget;


@interface CCBPublisher : NSObject

@property (nonatomic, strong) id<TaskStatusUpdaterProtocol> taskStatusUpdater;

// Which directories should be published
@property (nonatomic, copy) NSArray *publishInputDirectories;

// Where should published files go
- (void)setPublishOutputDirectory:(NSString *)outputDirectory forTargetType:(CCBPublisherOSType)targetType;
- (NSString *)publishOutputDirectoryForTargetType:(CCBPublisherOSType)targetType;

- (id)initWithProjectSettings:(ProjectSettings *)someProjectSettings
                     warnings:(CCBWarnings *)someWarnings
                finishedBlock:(PublisherFinishBlock)finishBlock;

- (void)start;
- (void)startAsync;

- (void)cancel;

- (void)addPublishingTarget:(CCBPublishingTarget *)target;

@end