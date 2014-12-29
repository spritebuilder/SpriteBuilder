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
    dict[@"jsControlled"] = @(NO);

    dict[@"centeredOrigin"] = @([[CocosScene cocosScene] centeredOrigin]);
    dict[@"docDimensionsType"] = @(_document.docDimensionsType);
    dict[@"UUID"] = @(_document.UUID);
}

- (void)setNodeGraphInDict:(NSMutableDictionary *)dict
{
    NSMutableDictionary* nodeGraph = [CCBWriterInternal dictionaryFromCCObject:_sceneGraph.rootNode];
    dict[@"nodeGraph"] = nodeGraph;
}

- (void)setMetaDataInDict:(NSMutableDictionary *)dict
{
    dict[@"fileType"] = @"CocosBuilder";
    dict[@"fileVersion"] = @(kCCBFileFormatVersion);
}

- (void)setStageInDict:(NSMutableDictionary *)dict
{
    dict[@"stageBorder"] = @([[CocosScene cocosScene] stageBorder]);
    dict[@"stageColor"] = @(_document.stageColor);
}

- (void)setGuidesAndNotesInDict:(NSMutableDictionary *)dict
{
    dict[@"guides"] = [[CocosScene cocosScene].guideLayer serializeGuides];
    dict[@"notes"] = [[CocosScene cocosScene].notesLayer serializeNotes];
}

- (void)setGridSpacingInDict:(NSMutableDictionary *)dict
{
    dict[@"gridspaceWidth"] = [NSNumber numberWithInt:[CocosScene cocosScene].guideLayer.gridSize.width];
    dict[@"gridspaceHeight"] = [NSNumber numberWithInt:[CocosScene cocosScene].guideLayer.gridSize.height];
}

- (void)setJointsDataInDictDict:(NSMutableDictionary *)dict
{
    NSMutableArray * joints = [NSMutableArray array];
    for (CCNode * joint in _sceneGraph.joints.all)
    {
        [joints addObject:[CCBWriterInternal dictionaryFromCCObject:joint]];
    }

    dict[@"joints"] = joints;

    dict[@"SequencerJoints"] = [_sceneGraph.joints serialize];
}

- (void)setExportPathAndPluginInDict:(NSMutableDictionary *)dict
{
    if (_document.exportPath && _document.exportPlugIn)
    {
        dict[@"exportPlugIn"] = _document.exportPlugIn;
        dict[@"exportPath"] = _document.exportPath;
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
        dict[@"resolutions"] = resolutions;
        dict[@"currentResolution"] = @(_document.currentResolution);
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
        dict[@"sequences"] = sequences;
        dict[@"currentSequenceId"] = @(_sequenceId);
    }
}

@end
