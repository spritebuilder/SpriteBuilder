#import <Foundation/Foundation.h>
#import "RMResourceBase.h"
#import "ResourceTypes.h"

@interface RMResource : RMResourceBase <NSPasteboardWriting>

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, readonly) NSString *relativePath;
@property (nonatomic, strong) NSDate *modifiedTime;
@property (nonatomic, assign) CCBResourceType type;
@property (nonatomic, assign) BOOL touched;
@property (nonatomic, strong) id data;

- (instancetype)initWithFilePath:(NSString *)filePath;

- (void)loadData;

- (NSImage *)previewForResolution:(NSString *)res;
- (NSString*)absoluteAutoPathForResolution:(NSString *)res;

// Convenience method until SB uses kCCBResTypeSpriteSheet as type, which is never set
- (BOOL)isSpriteSheet;

@end