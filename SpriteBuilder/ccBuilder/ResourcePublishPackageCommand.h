#import <Foundation/Foundation.h>

#import "ResourceCommandContextMenuProtocol.h"
#import "ResourceCommandProtocol.h"
#import "CCBPublisherTypes.h"

@class ProjectSettings;
@class CCBPublisherController;
@class PublishOSSettings;
@class PackagePublishSettings;

typedef void (^PublisherCancelBlock)();


@interface ResourcePublishPackageCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;

@property (nonatomic, copy) NSString *publishDirectory;
@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSWindow *windowForModals;

@property (nonatomic, copy) PublisherFinishBlock finishBlock;
@property (nonatomic, copy) PublisherCancelBlock cancelBlock;

// For accessory view bindings only
@property (nonatomic, strong) PackagePublishSettings *settings;


@end