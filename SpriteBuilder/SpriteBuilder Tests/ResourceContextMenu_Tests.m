//
//  ResourceContextMenu_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 04.06.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "ResourceContextMenu.h"
#import "ResourceCommandController.h"

@interface ResourceContextMenu_Tests : XCTestCase

@end


@implementation ResourceContextMenu_Tests

- (void)testShowMenuItemsForEmptySelection
{
    ResourceContextMenu *resourceContextMenu = [[ResourceContextMenu alloc] initWithActionTarget:nil resources:@[]];

    XCTAssertTrue([self menu:resourceContextMenu containsItemWithSelector:@selector(newFile:)]);
    XCTAssertTrue([self menu:resourceContextMenu containsItemWithSelector:@selector(newFolder:)]);
    XCTAssertEqual([resourceContextMenu itemArray].count, 2);
}

- (BOOL)menu:(NSMenu *)menu containsItemWithSelector:(SEL)selector
{
    NSArray *items = [menu itemArray];
    for (NSMenuItem *menuItem in items)
    {
        if (menuItem.action == selector)
        {
            return YES;
        }
    }
    return NO;
}

@end
