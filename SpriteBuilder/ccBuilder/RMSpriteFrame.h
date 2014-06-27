#import <Foundation/Foundation.h>
#import "RMResourceBase.h"


@interface RMSpriteFrame : RMResourceBase
{
    NSString *spriteSheetFile;
    NSString *spriteFrameName;
}

@property (nonatomic, copy) NSString *spriteSheetFile;
@property (nonatomic, copy) NSString *spriteFrameName;

@end