#import <Foundation/Foundation.h>

#import "ResourceCommandProtocol.h"
#import "CCBPublisherTypes.h"

@class ProjectSettings;
@class CCBPublisherController;

typedef void (^PublisherCancelBlock)();


@interface ResourcePublishPackageCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;

@property (nonatomic, copy) NSString *publishDirectory;
@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSWindow *windowForModals;

@property (nonatomic, copy) PublisherFinishBlock finishBlock;
@property (nonatomic, copy) PublisherCancelBlock cancelBlock;

@end