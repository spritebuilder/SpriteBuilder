#import <Foundation/Foundation.h>

@class ResourceActionController;


@interface ResourceContextMenu : NSMenu

@property (nonatomic, strong, readonly) id resource;
@property (nonatomic, strong, readonly) NSArray *resources;
@property (nonatomic, strong) ResourceActionController *actionController;

- (instancetype)initWithResource:(id)resource actionController:(ResourceActionController *)actionController resources:(NSArray *)resources;

@end