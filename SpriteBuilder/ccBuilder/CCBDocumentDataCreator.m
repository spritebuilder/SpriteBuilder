#import "CCBDocumentDataCreator.h"
#import "CCNode.h"
#import "SceneGraph.h"
#import "CCBDocument.h"
#import "CCBWriterInternal.h"
#import "CCBReaderInternal.h"
#import "GuidesLayer.h"
#import "NotesLayer.h"
#import "ProjectSettings.h"
#import "AppDelegate.h"
#import "ResolutionSetting.h"
#import "SequencerSequence.h"

@interface CCBDocumentDataCreator ()

@property (nonatomic, strong) SceneGraph *sceneGraph;
@property (nonatomic, strong) CCBDocument *document;
@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic) int sequenceId;

@end


@implementation CCBDocumentDataCreator

- (instancetype)init
{
    NSLog(@"Use designated initializer");
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithSceneGraph:(SceneGraph *)sceneGraph
                          document:(CCBDocument *)document
                   projectSettings:(ProjectSettings *)projectSettings
                        sequenceId:(int)sequenceId
{
    NSAssert(sceneGraph != nil, @"sceneGraph must not be nil");
    NSAssert(document != nil, @"document must not be nil");
    NSAssert(projectSettings != nil, @"projectSettings must not be nil");

    self = [super init];
    if (self)
    {
        self.sceneGraph = sceneGraph;
        self.document = document;
        self.projectSettings = projectSettings;
        self.sequenceId = sequenceId;
    }

    return self;
}

- (NSMutableDictionary *)createData;
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];

    [self setNodeGraphInDict:dict];

    [self setMetaDataInDict:dict];

    [self setStageInDict:dict];

    [self setGuidesAndNotesInDict:dict];

    [self setGridSpacingInDict:dict];

    [self setJointsDataInDictDict:dict];

    [self setResolutionsInDict:dict];

    [self setSequencerTimelinesInDict:dict];

    [self setExportPathAndPluginInDict:dict];

    [self setMiscDataInDict:dict];

    return dict;
}

- (void)setMiscDataInDict:(NSMutableDictionary *)dict
{
    // TODO: obsolete legacy code for javascript
    [dict setObject:@(NO) forKey:@"jsControlled"];

    [dict setObject:@([[CocosScene cocosScene] centeredOrigin]) forKey:@"centeredOrigin"];
    [dict setObject:@(_document.docDimensionsType) forKey:@"docDimensionsType"];
    [dict setObject:@(_document.UUID) forKey:@"UUID"];
}

- (void)setNodeGraphInDict:(NSMutableDictionary *)dict
{
    NSMutableDictionary* nodeGraph = [CCBWriterInternal dictionaryFromCCObject:_sceneGraph.rootNode];
    [dict setObject:nodeGraph forKey:@"nodeGraph"];
}

- (void)setMetaDataInDict:(NSMutableDictionary *)dict
{
    [dict setObject:@"CocosBuilder" forKey:@"fileType"];
    [dict setObject:@(kCCBFileFormatVersion) forKey:@"fileVersion"];
}

- (void)setStageInDict:(NSMutableDictionary *)dict
{
    [dict setObject:[NSNumber numberWithInt:[[CocosScene cocosScene] stageBorder]] forKey:@"stageBorder"];
    [dict setObject:[NSNumber numberWithInt:_document.stageColor] forKey:@"stageColor"];
}

- (void)setGuidesAndNotesInDict:(NSMutableDictionary *)dict
{
    [dict setObject:[[CocosScene cocosScene].guideLayer serializeGuides] forKey:@"guides"];
    [dict setObject:[[CocosScene cocosScene].notesLayer serializeNotes] forKey:@"notes"];
}

- (void)setGridSpacingInDict:(NSMutableDictionary *)dict
{
    [dict setObject:[NSNumber numberWithInt:[CocosScene cocosScene].guideLayer.gridSize.width] forKey:@"gridspaceWidth"];
    [dict setObject:[NSNumber numberWithInt:[CocosScene cocosScene].guideLayer.gridSize.height] forKey:@"gridspaceHeight"];
}

- (void)setJointsDataInDictDict:(NSMutableDictionary *)dict
{
    NSMutableArray * joints = [NSMutableArray array];
    for (CCNode * joint in _sceneGraph.joints.all)
    {
        [joints addObject:[CCBWriterInternal dictionaryFromCCObject:joint]];
    }

    [dict setObject:joints forKey:@"joints"];

    if (_projectSettings.engine != CCBTargetEngineSpriteKit)
    {
        [dict setObject:[_sceneGraph.joints serialize] forKey:@"SequencerJoints"];
    }
}

- (void)setExportPathAndPluginInDict:(NSMutableDictionary *)dict
{
    if (_document.exportPath && _document.exportPlugIn)
    {
        [dict setObject:_document.exportPlugIn forKey:@"exportPlugIn"];
        [dict setObject:_document.exportPath forKey:@"exportPath"];
    }
}

- (void)setResolutionsInDict:(NSMutableDictionary *)dict
{
    if (_document.resolutions)
    {
        NSMutableArray* resolutions = [NSMutableArray array];
        for (ResolutionSetting* r in _document.resolutions)
        {
            [resolutions addObject:[r serialize]];
        }
        [dict setObject:resolutions forKey:@"resolutions"];
        [dict setObject:@(_document.currentResolution) forKey:@"currentResolution"];
    }
}

- (void)setSequencerTimelinesInDict:(NSMutableDictionary *)dict
{
    if (_document.sequences)
    {
        NSMutableArray* sequences = [NSMutableArray array];
        for (SequencerSequence* seq in _document.sequences)
        {
            [sequences addObject:[seq serialize]];
        }
        [dict setObject:sequences forKey:@"sequences"];
        [dict setObject:@(_sequenceId) forKey:@"currentSequenceId"];
    }
}



@end