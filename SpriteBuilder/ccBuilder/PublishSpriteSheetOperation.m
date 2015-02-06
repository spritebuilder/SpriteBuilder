#import "PublishSpriteSheetOperation.h"

#import "CCBFileUtil.h"
#import "Tupac.h"
#import "PublishingTaskStatusProgress.h"
#import "ProjectSettings.h"
#import "ResourcePropertyKeys.h"
#import "MiscConstants.h"
#import "NSString+Publishing.h"


@interface PublishSpriteSheetOperation()

@property (nonatomic, strong) Tupac *packer;
@property (nonatomic, copy) NSString *previewFilePath;
@property (nonatomic) int format_ios;
@property (nonatomic) BOOL format_ios_dither;
@property (nonatomic) BOOL format_ios_compress;
@property (nonatomic) int format_android;
@property (nonatomic) BOOL format_android_dither;
@property (nonatomic) BOOL format_android_compress;
@property (nonatomic) BOOL trim;

@end


// To prevent generation of previews for the same sprite sheet across resolutions
// the names are stored and queried in this var
static NSMutableSet *__spriteSheetPreviewsGenerated;


@implementation PublishSpriteSheetOperation

+ (void)initialize
{
    [self resetSpriteSheetPreviewsGeneration];
}

+ (void)resetSpriteSheetPreviewsGeneration
{
    __spriteSheetPreviewsGenerated = [NSMutableSet set];
}

- (void)main
{
    [super main];

    [self assertProperties];

    [self publishSpriteSheet];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)assertProperties
{
    NSAssert(_spriteSheetFile != nil, @"spriteSheetFile should not be nil");
    NSAssert(_subPath != nil, @"subPath should not be nil");
    NSAssert(_srcDirs != nil, @"srcDirs should not be nil");
    NSAssert(_resolution != nil, @"resolution should not be nil");
    NSAssert(_srcSpriteSheetDate != nil, @"srcSpriteSheetDate should not be nil");
    NSAssert(_publishDirectory != nil, @"publishDirectory should not be nil");
    NSAssert(_publishedPNGFiles != nil, @"publishedPNGFiles should not be nil");
}

- (void)publishSpriteSheet
{
    [_publishingTaskStatusProgress updateStatusText:[NSString stringWithFormat:@"Generating sprite sheet %@...", [_subPath lastPathComponent]]];

    self.spriteSheetFile = [_spriteSheetFile filepathWithResolutionTag:_resolution];

    [self loadSettings];

    [self configurePacker];

    NSArray *createdFiles = [_packer createTextureAtlasFromDirectoryPaths:_srcDirs];

    [self addCreatedPNGFilesToCreatedFilesSet:createdFiles];

    [self processWarnings];

    [self setDateForCreatedFiles:createdFiles];
}

- (void)setDateForCreatedFiles:(NSArray *)createFiles
{
    for (NSString *filePath in createFiles)
    {
        [CCBFileUtil setModificationDate:_srcSpriteSheetDate forFile:filePath];
    }
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
    if (![__spriteSheetPreviewsGenerated containsObject:_subPath])
    {
        self.previewFilePath = [_publishDirectory stringByAppendingPathExtension:PNG_PREVIEW_IMAGE_SUFFIX];
        [__spriteSheetPreviewsGenerated addObject:_subPath];
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
    _packer.trim = _trim;

    [self setImageFormatDependingOnTarget];

    [self setTextureMaxSize];
}

- (void)setImageFormatDependingOnTarget
{
    if (_osType == kCCBPublisherOSTypeIOS)
    {
        _packer.imageFormat = self.format_ios;
        _packer.compress = self.format_ios_compress;
        _packer.dither = self.format_ios_dither;
    }
    else if (_osType == kCCBPublisherOSTypeAndroid)
    {
        _packer.imageFormat = self.format_android;
        _packer.compress = self.format_android_compress;
        _packer.dither = self.format_android_dither;
    }
}

- (void)setTextureMaxSize
{
    if ([_resolution unsignedIntegerValue] == 1)
    {
        _packer.maxTextureSize = 1024;
    }
    else if ([_resolution unsignedIntegerValue] == 2)
    {
        _packer.maxTextureSize = 2048;
    }
    else if ([_resolution unsignedIntegerValue] == 4)
    {
        _packer.maxTextureSize = 4096;
    }
}

- (void)loadSettings
{
    self.format_ios = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_IOS_IMAGE_FORMAT] intValue];
    self.format_ios_dither = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_IOS_IMAGE_DITHER] boolValue];
    self.format_ios_compress = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_IOS_IMAGE_COMPRESS] boolValue];
    self.format_android = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_ANDROID_IMAGE_FORMAT] intValue];
    self.format_android_dither = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_ANDROID_IMAGE_DITHER] boolValue];
    self.format_android_compress = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_ANDROID_IMAGE_COMPRESS] boolValue];
    self.trim = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_TRIM_SPRITES] boolValue];
}

- (void)cancel
{
    [super cancel];
    [_packer cancel];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"file: %@, res: %@, osType: %i, filefull: %@, srcdirs: %@, publishDirectory: %@, date: %@",
                                      [_spriteSheetFile lastPathComponent], _resolution, _osType, _spriteSheetFile, _srcDirs, _publishDirectory, _srcSpriteSheetDate];
}


@end