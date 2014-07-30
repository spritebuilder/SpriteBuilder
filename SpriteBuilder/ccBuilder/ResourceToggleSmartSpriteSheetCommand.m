#import "ResourceToggleSmartSpriteSheetCommand.h"

#import "RMDirectory.h"
#import "ProjectSettings.h"
#import "RMResource.h"
#import "ResourceTypes.h"

@implementation ResourceToggleSmartSpriteSheetCommand

- (void)execute
{
    NSAssert(_projectSettings != nil, @"Project settings nil, cannot toggle smartsheets.");

    if (_resources.count == 0)
    {
        return;
    }

    RMResource *resource = (RMResource *) _resources.firstObject;
    RMDirectory *directory = resource.data;

    if (directory.isDynamicSpriteSheet)
    {
        [_projectSettings removeSmartSpriteSheet:resource];
    }
    else
    {
        [_projectSettings makeSmartSpriteSheet:resource];
    }
}


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    id firstResource = resources.firstObject;
    if ([firstResource isKindOfClass:[RMResource class]])
    {
        RMResource *clickedResource = firstResource;
        if (clickedResource.type == kCCBResTypeDirectory)
        {
            RMDirectory *dir = clickedResource.data;
            if (dir.isDynamicSpriteSheet)
            {
                return @"Remove Smart Sprite Sheet";
            }
            else
            {
                return @"Make Smart Sprite Sheet";
            }
        }
    }
    return @"Make Smart Sprite Sheet";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    id firstResource = resources.firstObject;
    if ([firstResource isKindOfClass:[RMResource class]])
    {
        RMResource *clickedResource = firstResource;
        if (clickedResource.type == kCCBResTypeDirectory)
        {
            return YES;
        }
    }
    return NO;
}

@end