#import "RMDirectory.h"
#import "MiscConstants.h"
#import "ResourceTypes.h"
#import "ProjectSettings.h"
#import "AppDelegate.h"
#import "RMResource.h"


@implementation RMDirectory

@synthesize count;
@synthesize dirPath;
@synthesize resources;
@synthesize any;
@synthesize images;
@synthesize animations;
@synthesize bmFonts;
@synthesize ttfFonts;
@synthesize ccbFiles;
@synthesize audioFiles;

- (id) init
{
    self = [super init];
    if (!self) return NULL;

    resources = [[NSMutableDictionary alloc] init];
    any = [[NSMutableArray alloc] init];
    images = [[NSMutableArray alloc] init];
    animations = [[NSMutableArray alloc] init];
    bmFonts = [[NSMutableArray alloc] init];
    ttfFonts = [[NSMutableArray alloc] init];
    ccbFiles = [[NSMutableArray alloc] init];
    audioFiles = [[NSMutableArray alloc] init];

    return self;
}

- (NSArray*)resourcesForType:(int)type
{
    if (type == kCCBResTypeNone) return any;
    if (type == kCCBResTypeImage) return images;
    if (type == kCCBResTypeBMFont) return bmFonts;
    if (type == kCCBResTypeTTF) return ttfFonts;
    if (type == kCCBResTypeAnimation) return animations;
    if (type == kCCBResTypeCCBFile) return ccbFiles;
    if (type == kCCBResTypeAudio) return audioFiles;
    return NULL;
}

- (BOOL) isDynamicSpriteSheet
{
    if (dirPath)
    {
        ProjectSettings* projectSettings = [AppDelegate appDelegate].projectSettings;

        RMResource* dirRes = [[RMResource alloc] init];
        dirRes.type = kCCBResTypeDirectory;
        dirRes.filePath = dirPath;

        if (projectSettings)
        {
            BOOL isSmartSpriteSheet = [[projectSettings propertyForResource:dirRes andKey:@"isSmartSpriteSheet"] boolValue];
            return isSmartSpriteSheet;
        }
    }
    return NO;
}

- (void) setDirPath:(NSString *)dp
{
    if (dp != dirPath)
    {
        dirPath = dp;
    }
}

- (NSComparisonResult) compare:(RMDirectory*)dir
{
    return [dirPath compare:dir.dirPath];
}

@end
