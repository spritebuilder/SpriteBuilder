#import "PublishSpriteSheetOperation.h"
#import "CCBFileUtil.h"
#import "Tupac.h"
#import "CCBWarnings.h"
#import "AppDelegate.h"
#import "ProjectSettings.h"

@interface PublishSpriteSheetOperation()

@property (nonatomic, weak) AppDelegate *appDelegate;
@property (nonatomic, weak) CCBWarnings *warnings;
@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, strong) Tupac *packer;
@property (nonatomic, copy) NSString *previewFilePath;

@property (nonatomic) int format_ios;
@property (nonatomic) BOOL format_ios_dither;
@property (nonatomic) BOOL format_ios_compress;
@property (nonatomic) int format_android;
@property (nonatomic) BOOL format_android_dither;
@property (nonatomic) BOOL format_android_compress;

@end

@implementation PublishSpriteSheetOperation

- (instancetype)initWithAppDelegate:(AppDelegate *)appDelegate warnings:(CCBWarnings *)warnings projectSettings:(ProjectSettings *)projectSettings
{
    self = [super init];
    if (self)
    {
        self.appDelegate = appDelegate;
        self.warnings = warnings;
        self.projectSettings = projectSettings;

        self.packer = [[Tupac alloc] init];
    }

    return self;
}

- (void)main
{
    [self loadSettings];

    [self configurePacker];

    [_appDelegate modalStatusWindowUpdateStatusText:[NSString stringWithFormat:@"Generating sprite sheet %@...", [[_subPath stringByAppendingPathExtension:@"plist"]
                                                                                                                           lastPathComponent]]];
    // heavy task
    NSArray *createdFiles = [_packer createTextureAtlasFromDirectoryPaths:_srcDirs];

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
    else if (_targetType == kCCBPublisherTargetTypeAndroid)
    {
        _packer.imageFormat = self.format_android;
        _packer.compress = self.format_android_compress;
        _packer.dither = self.format_android_dither;
    }
    /*
     else if (targetType == kCCBPublisherTargetTypeHTML5)
     {
     _packer.imageFormat = ssSettings.textureFileFormatHTML5;
     _packer.compress = NO;
     _packer.dither = ssSettings.ditherHTML5;
     }
     */
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
    self.format_android = [[_projectSettings valueForRelPath:_subPath andKey:@"format_android"] intValue];
    self.format_android_dither = [[_projectSettings valueForRelPath:_subPath andKey:@"format_android_dither"] boolValue];
    self.format_android_compress = [[_projectSettings valueForRelPath:_subPath andKey:@"format_android_compress"] boolValue];
}

- (void)cancel
{
    NSLog(@"[%@] %@@%@ cancelled", [self class], [_spriteSheetFile lastPathComponent], _resolution);
    // TODO
    [super cancel];
    [_packer cancel];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"TODO"];
}


@end