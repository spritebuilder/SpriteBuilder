#import <Foundation/Foundation.h>
#import "RMResourceBase.h"

@interface RMResource : RMResourceBase <NSPasteboardWriting>

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, readonly) NSString *relativePath;
@property (nonatomic, strong) NSDate *modifiedTime;
@property (nonatomic, assign) int type;
@property (nonatomic, assign) BOOL touched;
@property (nonatomic, strong) id data;

- (instancetype)initWithFilePath:(NSString *)filePath;

- (void)loadData;

- (NSImage *)previewForResolution:(NSString *)res;

@end