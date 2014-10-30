//
//  ResourceDuplicateCommand.m
//  SpriteBuilder
//
//  Created by Martin Walsh on 30/10/2014.
//
//

#import "ResourceDuplicateCommand.h"

#import "ResourceManager.h"
#import "RMResource.h"

@implementation ResourceDuplicateCommand

- (void)execute
{
    RMResource *resource = _resources.firstObject;

    switch (resource.type) {
        case kCCBResTypeCCBFile:
            [ResourceManager copyResourceFile:resource];
            break;
        default:
            //NSAlert(@"Selected resource does not support duplication.");
            break;
    }
}

#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"Duplicate File";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    id firstResource = resources.firstObject;
    if ([firstResource isKindOfClass:[RMResource class]])
    {
        RMResource *clickedResource = firstResource;
        if (clickedResource.type == kCCBResTypeCCBFile)
        {
            return YES;
        }
    }
    return NO;
}

@end
