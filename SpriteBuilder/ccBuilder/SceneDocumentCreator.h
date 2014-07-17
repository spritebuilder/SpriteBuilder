#import <Foundation/Foundation.h>

@class SceneGraph;
@class CCBDocument;
@class ProjectSettings;


@interface SceneDocumentCreator : NSObject

- (instancetype)initWithSceneGraph:(SceneGraph *)sceneGraph
                          document:(CCBDocument *)document
                   projectSettings:(ProjectSettings *)projectSettings
                        sequenceId:(int)sequenceId;

- (NSMutableDictionary *)createDocument;

@end