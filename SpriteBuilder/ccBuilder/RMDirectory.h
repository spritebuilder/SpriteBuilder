#import <Foundation/Foundation.h>
#import "RMResourceBase.h"


@interface RMDirectory : RMResourceBase
{
    int count;
    NSString *dirPath;
    NSMutableDictionary *resources;
    BOOL isDynamicSpriteSheet;

    NSMutableArray *any;
    NSMutableArray *images;
    NSMutableArray *animations;
    NSMutableArray *bmFonts;
    NSMutableArray *ttfFonts;
    NSMutableArray *ccbFiles;
    NSMutableArray *audioFiles;
}

@property (nonatomic, assign) int count;
@property (nonatomic, copy) NSString *dirPath;
@property (nonatomic, readonly) NSMutableDictionary *resources;
@property (nonatomic, readonly) BOOL isDynamicSpriteSheet;

@property (nonatomic, readonly) NSMutableArray *any;
@property (nonatomic, readonly) NSMutableArray *images;
@property (nonatomic, readonly) NSMutableArray *animations;
@property (nonatomic, readonly) NSMutableArray *bmFonts;
@property (nonatomic, readonly) NSMutableArray *ttfFonts;
@property (nonatomic, readonly) NSMutableArray *ccbFiles;
@property (nonatomic, readonly) NSMutableArray *audioFiles;

- (NSArray *)resourcesForType:(int)type;

@end
