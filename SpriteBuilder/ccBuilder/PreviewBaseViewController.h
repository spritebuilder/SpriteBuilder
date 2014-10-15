#import <Foundation/Foundation.h>
#import "PreviewViewControllerProtocol.h"

@class RMResource;
@class ProjectSettings;

@interface PreviewBaseViewController : NSViewController
{
    RMResource *_previewedResource;
    __weak ProjectSettings *_projectSettings;
}

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, strong) RMResource *previewedResource;
@property (nonatomic) BOOL initialUpdate;

// Provide a block with all the property setting for the initial values, this will
// prevent marking the resource as dirty
- (void)setInitialValues:(dispatch_block_t)setterBlock;

// Sets the previewed resource's property
// Set isAudio yes if it's an audio resource, this will prevent removal of a property for values that will yield false for if (value)
//    This is an inconsitency, which should be addressed at some point in the future
- (void)setValue:(id)value withName:(NSString *)name isAudio:(BOOL)isAudio;

@end