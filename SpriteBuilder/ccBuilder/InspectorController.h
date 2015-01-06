#import <Foundation/Foundation.h>

@class AppDelegate;
@class CocosScene;
@class SequencerHandler;
@class PropertyInspectorTemplateHandler;


@interface InspectorController : NSObject

@property (nonatomic, weak) AppDelegate *appDelegate;
@property (nonatomic, weak) CocosScene *cocosScene;
@property (nonatomic, weak) SequencerHandler *sequenceHandler;

@property (nonatomic, weak) IBOutlet NSScrollView *inspectorCodeScroll;
@property (nonatomic, weak) IBOutlet NSScrollView *inspectorScroll;
@property (nonatomic, weak) IBOutlet PropertyInspectorTemplateHandler *propertyInspectorTemplateHandler;
@property (nonatomic, weak) IBOutlet NSView *inspectorPhysics;

+ (InspectorController *)sharedController;
+ (void)setSingleton:(InspectorController *)sharedController;

- (void)setupInspectorPane;

- (void)refreshAllProperties;
- (void)refreshProperty:(NSString *)name;

- (void)refreshPropertiesOfType:(NSString *)type;

- (void)updateInspectorFromSelection;

@end