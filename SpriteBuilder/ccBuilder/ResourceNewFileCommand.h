#import <Foundation/Foundation.h>

#import "ResourceCommandProtocol.h"
#import "ResourceCommandContextMenuProtocol.h"

@class ResourceManager;

@interface ResourceNewFileCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, weak) NSOutlineView *outlineView;
@property (nonatomic, weak) NSWindow *windowForModals;
@property (nonatomic, weak) ResourceManager *resourceManager;

@end