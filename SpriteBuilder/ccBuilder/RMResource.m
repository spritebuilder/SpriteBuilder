#import <Quartz/Quartz.h>
#import "RMResource.h"
#import "CCBFileUtil.h"
#import "ResourceTypes.h"
#import "RMAnimation.h"
#import "CCBAnimationParser.h"
#import "CCBSpriteSheetParser.h"
#import "RMSpriteFrame.h"
#import "ResourceManagerUtil.h"


@implementation RMResource

@synthesize type, modifiedTime, touched, data, filePath;

- (void) loadData
{
    if (type == kCCBResTypeSpriteSheet)
    {
        NSArray* spriteFrameNames = [CCBSpriteSheetParser listFramesInSheet:filePath];
        NSMutableArray* spriteFrames = [NSMutableArray arrayWithCapacity:[spriteFrameNames count]];
        for (NSString* frameName in spriteFrameNames)
        {
            RMSpriteFrame* frame = [[RMSpriteFrame alloc] init];
            frame.spriteFrameName = frameName;
            frame.spriteSheetFile = self.filePath;

            [spriteFrames addObject:frame];
        }
        self.data = spriteFrames;
    }
    else if (type == kCCBResTypeAnimation)
    {
        NSArray* animationNames = [CCBAnimationParser listAnimationsInFile:filePath];
        NSMutableArray* animations = [NSMutableArray arrayWithCapacity:[animationNames count]];
        for (NSString* animationName in animationNames)
        {
            RMAnimation* anim = [[RMAnimation alloc] init];
            anim.animationName = animationName;
            anim.animationFile = self.filePath;

            [animations addObject:anim];
        }
        self.data = animations;
    }
    else if (type == kCCBResTypeDirectory)
    {
        // Ignore changed directories
    }
    else
    {
        self.data = NULL;
    }
}

@dynamic relativePath;
- (NSString*) relativePath
{
    return [ResourceManagerUtil relativePathFromAbsolutePath: self.filePath];
}

- (NSImage*) previewForResolution:(NSString *)res
{
    if (!res) res = @"auto";

    if (type == kCCBResTypeImage)
    {
        NSString* fileName = [filePath lastPathComponent];
        NSString* dirPath = [filePath stringByDeletingLastPathComponent];
        NSString* resDirName = [@"resources-" stringByAppendingString:res];

        NSString* autoPath = [[dirPath stringByAppendingPathComponent:resDirName] stringByAppendingPathComponent:fileName];

        NSImage* img = [[NSImage alloc] initWithContentsOfFile:autoPath];
        return img;
    }

    return NULL;
}

- (NSComparisonResult) compare:(id) obj
{
    RMResource* res = obj;

    if (res.type < self.type)
    {
        return NSOrderedDescending;
    }
    else if (res.type > self.type)
    {
        return NSOrderedAscending;
    }
    else
    {
        return [[self.filePath lastPathComponent] compare:[res.filePath lastPathComponent] options:NSNumericSearch|NSForcedOrderingSearch|NSCaseInsensitiveSearch];
    }
}

// Paste board

- (id) pasteboardPropertyListForType:(NSString *)pbType
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];

    if ([pbType isEqualToString:@"com.cocosbuilder.RMResource"])
    {
        [dict setObject:[NSNumber numberWithInt:type] forKey:@"type"];
        [dict setObject:filePath forKey:@"filePath"];
        return dict;
    }
    else if ([pbType isEqualToString:@"com.cocosbuilder.texture"])
    {
        [dict setObject:self.relativePath forKey:@"spriteFile"];
        return dict;
    }
    else if ([pbType isEqualToString:@"com.cocosbuilder.ccb"])
    {
        [dict setObject:self.relativePath forKey:@"ccbFile"];
        return dict;
    }
    else if ([pbType isEqualToString:@"com.cocosbuilder.wav"])
    {
        [dict setObject:self.relativePath forKey:@"wavFile"];
        return dict;
    }
    return NULL;
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    NSMutableArray* pbTypes = [NSMutableArray arrayWithObject: @"com.cocosbuilder.RMResource"];
    if (type == kCCBResTypeImage)
    {
        [pbTypes addObject:@"com.cocosbuilder.texture"];
    }
    else if (type == kCCBResTypeCCBFile)
    {
        [pbTypes addObject:@"com.cocosbuilder.ccb"];
    }
    else if(type == kCCBResTypeAudio)
    {
        [pbTypes addObject:@"com.cocosbuilder.wav"];
    }

    return pbTypes;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)pbType pasteboard:(NSPasteboard *)pasteboard
{
    if ([pbType isEqualToString:@"com.cocosbuilder.RMResource"]) return NSPasteboardWritingPromised;
    if ([pbType isEqualToString:@"com.cocosbuilder.texture"] && type == kCCBResTypeImage) return NSPasteboardWritingPromised;
    if ([pbType isEqualToString:@"com.cocosbuilder.ccb"] && type == kCCBResTypeCCBFile) return NSPasteboardWritingPromised;
    if ([pbType isEqualToString:@"com.cocosbuilder.wav"] && type == kCCBResTypeAudio) return NSPasteboardWritingPromised;
    return 0;
}

// ImageKit representation

- (NSString *) imageUID
{
    return self.relativePath;
}

- (NSString *) imageRepresentationType
{
    return IKImageBrowserPathRepresentationType;
}

- (id) imageRepresentation
{
    if (self.type == kCCBResTypeImage)
    {
        NSFileManager* fm = [NSFileManager defaultManager];

        NSString* dir = [self.filePath stringByDeletingLastPathComponent];
        NSString* file = [self.filePath lastPathComponent];
        NSString* autoPath = [[dir stringByAppendingPathComponent:@"resources-auto"] stringByAppendingPathComponent:file];

        if ([fm fileExistsAtPath:autoPath]) return autoPath;
        else return NULL;
    }
    else if (self.type == kCCBResTypeCCBFile)
    {
        NSFileManager* fm = [NSFileManager defaultManager];

        NSString* previewPath = [self.filePath stringByAppendingPathExtension:@"ppng"];
        if ([fm fileExistsAtPath:previewPath]) return previewPath;
        else return NULL;
    }
    else
    {
        return NULL;
    }
}

- (NSUInteger) imageVersion
{
    if (self.type == kCCBResTypeImage)
    {
        NSFileManager* fm = [NSFileManager defaultManager];

        NSString* dir = [self.filePath stringByDeletingLastPathComponent];
        NSString* file = [self.filePath lastPathComponent];
        NSString* autoPath = [[dir stringByAppendingPathComponent:@"resources-auto"] stringByAppendingPathComponent:file];

        if ([fm fileExistsAtPath:autoPath])
        {
            NSDate* fileDate = [CCBFileUtil modificationDateForFile:autoPath];
            return ((NSUInteger)[fileDate timeIntervalSinceReferenceDate]);
        }
        else return 0;
    }
    else if (self.type == kCCBResTypeCCBFile)
    {
        NSFileManager* fm = [NSFileManager defaultManager];

        NSString* previewPath = [self.filePath stringByAppendingPathExtension:@"ppng"];
        if ([fm fileExistsAtPath:previewPath])
        {
            NSDate* fileDate = [CCBFileUtil modificationDateForFile:previewPath];
            return ((NSUInteger)[fileDate timeIntervalSinceReferenceDate]);
        }
        else return 0;
    }
    else
    {
        return 0;
    }
}

- (NSString *) imageTitle
{
    return [[self.filePath lastPathComponent] stringByDeletingPathExtension];
}

- (BOOL) isSelectable
{
    return YES;
}

// Deallocation


@end