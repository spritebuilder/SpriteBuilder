#import <Foundation/Foundation.h>

#import "ResourceCommandProtocol.h"
#import "ResourceCommandContextMenuProtocol.h"

@class ProjectSettings;

@interface ResourceToggleSmartSpriteSheetCommand :  NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, weak) ProjectSettings *projectSettings;

@end