#import <Foundation/Foundation.h>

@class CCNode;
@class CocosScene;
@class SequencerHandler;

@interface InspectorPropertyPaneBuilder : NSObject

@property (nonatomic, strong, readonly) CCNode *node;

@property (nonatomic, weak) NSView *currentView;
@property (nonatomic, weak) NSScrollView *currentScrollView;

@property (nonatomic, weak) CocosScene *cocosScene;
@property (nonatomic, weak) SequencerHandler *sequenceHandler;
@property (nonatomic, weak) NSView *inspectorPhysics;

- (instancetype)initWithIsCodeConnectionPane:(BOOL)isCodeConnectionPane node:(CCNode *)node;

- (NSDictionary *)buildAndCreatePropertyViewMap;

@end