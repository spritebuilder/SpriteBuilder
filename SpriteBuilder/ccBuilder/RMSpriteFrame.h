#import <Foundation/Foundation.h>


@interface RMSpriteFrame : NSObject
{
    NSString *spriteSheetFile;
    NSString *spriteFrameName;
}

@property (nonatomic, copy) NSString *spriteSheetFile;
@property (nonatomic, copy) NSString *spriteFrameName;

@end