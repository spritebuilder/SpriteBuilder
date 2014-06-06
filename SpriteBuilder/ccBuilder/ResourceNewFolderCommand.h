#import <Foundation/Foundation.h>

#import "ResourceCommandProtocol.h"
#import "ResourceCommandContextMenuProtocol.h"

@class ResourceManager;

@interface ResourceNewFolderCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, weak) NSOutlineView *outlineView;
@property (nonatomic, weak) ResourceManager *resourceManager;

@end