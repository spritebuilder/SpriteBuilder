//
//  NSPasteboard+CCB.m
//  CocosBuilder
//
//  Created by Viktor on 6/20/13.
//
//

#import "NSPasteboard+CCB.h"

@implementation NSPasteboard (CCB)

- (NSArray*) propertyListsForType:(NSString*) type
{
    NSArray* pbs = [self pasteboardItems];
    NSMutableArray* plists = [NSMutableArray array];
    
    for (NSPasteboardItem* item in pbs)
    {
        id plist = [item propertyListForType:type];
        if (plist)
        {
            [plists addObject:plist];
        }
    }
    
    return plists;
}

@end
