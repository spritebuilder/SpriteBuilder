#import <Foundation/Foundation.h>

#import "ResourceCommandProtocol.h"


@interface ResourceCreateKeyframesCommand : NSObject <ResourceCommandProtocol, ResourceCommandContextMenuProtocol>

@property (nonatomic, strong) NSArray *resources;

@end