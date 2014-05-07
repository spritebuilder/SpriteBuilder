#import <Foundation/Foundation.h>
#import "PublishBaseOperation.h"
#import "CCBWarnings.h"


@class CCBWarnings;
@class ProjectSettings;

@interface PublishSpriteSheetOperation : PublishBaseOperation

@property (nonatomic, copy) NSString *spriteSheetFile;
@property (nonatomic) CCBPublisherTargetType targetType;
@property (nonatomic, copy) NSString *subPath;
@property (nonatomic, strong) NSArray *srcDirs;
@property (nonatomic, copy) NSString *resolution;
@property (nonatomic, copy) NSDate *srcSpriteSheetDate;
@property (nonatomic, copy) NSString *publishDirectory;
@property (nonatomic, strong) NSMutableSet *publishedPNGFiles;

+ (void)resetSpriteSheetPreviewsGeneration;

@end

