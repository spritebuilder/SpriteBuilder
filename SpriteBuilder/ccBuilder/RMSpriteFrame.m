#import "RMSpriteFrame.h"
#import "CCBSpriteSheetParser.h"

@implementation RMSpriteFrame

@synthesize spriteFrameName, spriteSheetFile;

- (NSImage*) preview
{
    return [CCBSpriteSheetParser imageNamed:spriteFrameName fromSheet:spriteSheetFile];
}

@end