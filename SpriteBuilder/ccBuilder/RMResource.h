#import <Foundation/Foundation.h>
#import "RMResourceBase.h"

@interface RMResource : RMResourceBase <NSPasteboardWriting>
{
    int type;
    BOOL touched;
    NSString *filePath;
    NSDate *modifiedTime;
    id data;
}

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, readonly) NSString *relativePath;
@property (nonatomic, strong) NSDate *modifiedTime;
@property (nonatomic, assign) int type;
@property (nonatomic, assign) BOOL touched;
@property (nonatomic, strong) id data;

- (void)loadData;

- (NSImage *)previewForResolution:(NSString *)res;

@end