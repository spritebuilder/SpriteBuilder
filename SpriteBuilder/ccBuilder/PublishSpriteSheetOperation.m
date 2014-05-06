#import "PublishSpriteSheetOperation.h"

#import "CCBFileUtil.h"
#import "Tupac.h"
#import "PublishingTaskStatusProgress.h"
#import "ProjectSettings.h"

@interface PublishSpriteSheetOperation()

@property (nonatomic, strong) Tupac *packer;
@property (nonatomic, copy) NSString *previewFilePath;

@property (nonatomic) int format_ios;
@property (nonatomic) BOOL format_ios_dither;
@property (nonatomic) BOOL format_ios_compress;

@end

@implementation PublishSpriteSheetOperation

- (void)main
{
    NSLog(@"[%@] %@", [self class], [self description]);

    [self assertAllProperties];

    [self publishSpriteSheet];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)publishSpriteSheet
{
    [_publishingTaskStatusProgress updateStatusText:[NSString stringWithFormat:@"Generating sprite sheet %@...", [[_subPath stringByAppendingPathExtension:@"plist"] lastPathComponent]]];

    [self loadSettings];

    [self configurePacker];

    NSLog(@"[%@] start: %@", [self class], _spriteSheetFile);
    // heavy task
    NSArray *createdFiles = [_packer createTextureAtlasFromDirectoryPaths:_srcDirs];
    NSLog(@"[%@] end: %@", [self class], _spriteSheetFile);

    [self addCreatedPNGFilesToCreatedFilesSet:createdFiles];

    [self processWarnings];

    [CCBFileUtil setModificationDate:_srcSpriteSheetDate forFile:[_spriteSheetFile stringByAppendingPathExtension:@"plist"]];
}

- (void)addCreatedPNGFilesToCreatedFilesSet:(NSArray *)createdFiles
{
    for (NSString *aFile in createdFiles)
    {
        if ([[aFile pathExtension] isEqualToString:@"png"])
        {
            [_publishedPNGFiles addObject:aFile];
        }
    }
}

- (void)processWarnings
{
    if (_packer.errorMessage)
    {
        [_warnings addWarningWithDescription:_packer.errorMessage
                                     isFatal:NO
                                 relatedFile:_subPath
                                  resolution:_resolution];
    }
}

- (void)generatePreviewFilePath
{
    self.previewFilePath = nil;
    if (![_publishedSpriteSheetNames containsObject:_subPath])
    {
        self.previewFilePath = [_publishDirectory stringByAppendingPathExtension:@"ppng"];
        [_publishedSpriteSheetNames addObject:_subPath];
    }
}

- (void)configurePacker
{
    [self generatePreviewFilePath];

    self.packer = [[Tupac alloc] init];
    _packer.outputName = _spriteSheetFile;
    _packer.outputFormat = TupacOutputFormatCocos2D;
    _packer.previewFile = _previewFilePath;
    _packer.directoryPrefix = _subPath;
    _packer.border = YES;

    [self setImageFormatDependingOnTarget];

    [self setTextureMaxSize];
}

- (void)setImageFormatDependingOnTarget
{
    if (_targetType == kCCBPublisherTargetTypeIPhone)
    {
        _packer.imageFormat = self.format_ios;
        _packer.compress = self.format_ios_compress;
        _packer.dither = self.format_ios_dither;
    }
    else
    {
        NSLog(@"ERROR: Other publishing types not used any at the moment. Please refer to git history.");
    }
}

- (void)setTextureMaxSize
{
    if ([_resolution isEqualToString:@"phone"])
    {
        _packer.maxTextureSize = 1024;
    }
    else if ([_resolution isEqualToString:@"phonehd"])
    {
        _packer.maxTextureSize = 2048;
    }
    else if ([_resolution isEqualToString:@"tablet"])
    {
        _packer.maxTextureSize = 2048;
    }
    else if ([_resolution isEqualToString:@"tablethd"])
    {
        _packer.maxTextureSize = 4096;
    }
}

- (void)loadSettings
{
    self.format_ios = [[_projectSettings valueForRelPath:_subPath andKey:@"format_ios"] intValue];
    self.format_ios_dither = [[_projectSettings valueForRelPath:_subPath andKey:@"format_ios_dither"] boolValue];
    self.format_ios_compress = [[_projectSettings valueForRelPath:_subPath andKey:@"format_ios_compress"] boolValue];
}

- (void)cancel
{
    [super cancel];
    [_packer cancel];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"file: %@, res: %@, targetType: %i, filefull: %@, srcdirs: %@, publishDirectory: %@, date: %@",
                     [_spriteSheetFile lastPathComponent], _resolution, _targetType, _spriteSheetFile, _srcDirs, _publishDirectory, _srcSpriteSheetDate];
}


@end