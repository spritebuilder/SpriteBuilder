#import <Foundation/Foundation.h>

@class CCNode;
@class CocosScene;
@class SequencerHandler;

@interface InspectorPropertyPaneBuilder : NSObject

@property (nonatomic, weak) NSView *inspectorDocumentView;
@property (nonatomic, weak) NSView *inspectorCodeDocumentView;
@property (nonatomic, weak, readonly) CCNode *node;
@property (nonatomic, weak) IBOutlet NSScrollView *inspectorCodeScroll;
@property (nonatomic, weak) IBOutlet NSScrollView *inspectorScroll;
@property (nonatomic, weak) CocosScene *cocosScene;
@property (nonatomic, weak) SequencerHandler *sequenceHandler;
@property (nonatomic, weak) IBOutlet NSView *inspectorPhysics;

- (instancetype)initWithNode:(CCNode *)node;

- (NSDictionary *)buildAndCreatePropertyViewMap;

@end