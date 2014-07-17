#import <Foundation/Foundation.h>

@class SceneGraph;
@class CCBDocument;
@class ProjectSettings;


@interface CCBDocumentCreator : NSObject

- (instancetype)initWithSceneGraph:(SceneGraph *)sceneGraph
                          document:(CCBDocument *)document
                   projectSettings:(ProjectSettings *)projectSettings
                        sequenceId:(int)sequenceId;

// It actually should return a CCBDocument however there is some inconsequence around SB
- (NSMutableDictionary *)createDocument;

@end