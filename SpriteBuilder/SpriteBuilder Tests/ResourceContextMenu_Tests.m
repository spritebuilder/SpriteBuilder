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
#import "RMResource.h"
#import "ResourceTypes.h"
#import "RMPackage.h"

@interface ResourceContextMenu_Tests : XCTestCase

@end


@implementation ResourceContextMenu_Tests

- (void)testContextWithEmptySelection
{
    ResourceContextMenu *resourceContextMenu = [[ResourceContextMenu alloc] initWithActionTarget:nil resources:@[]];

    NSArray *selectors = @[
            @"newFile:",
            @"newFolder:",
            @"newPackage:"];

    [self assertMenu:resourceContextMenu containsItemsWithSelectorNames:selectors];
    [self assertMenuItemsCount:resourceContextMenu withExpectedSelectors:selectors];
}

- (void)testContextWithSelectedImage
{
    RMResource *resource = [[RMResource alloc] init];
    resource.type = kCCBResTypeImage;

    ResourceContextMenu *resourceContextMenu = [[ResourceContextMenu alloc] initWithActionTarget:nil resources:@[resource]];

    NSArray *selectors = @[
            @"newFile:",
            @"newFolder:",
            @"showResourceInFinder:",
            @"createKeyFrameFromSelection:",
            @"deleteResource:"];

    [self assertMenu:resourceContextMenu containsItemsWithSelectorNames:selectors];
    [self assertMenuItemsCount:resourceContextMenu withExpectedSelectors:selectors];
}

- (void)testContextWithSelectedPackage
{
    RMPackage *resource = [[RMPackage alloc] init];

    ResourceContextMenu *resourceContextMenu = [[ResourceContextMenu alloc] initWithActionTarget:nil resources:@[resource]];

    NSArray *selectors = @[
            @"newFile:",
            @"newFolder:",
            @"showResourceInFinder:",
            @"createKeyFrameFromSelection:",
            @"deleteResource:",
            @"exportPackage:"];

    [self assertMenu:resourceContextMenu containsItemsWithSelectorNames:selectors];
    [self assertMenuItemsCount:resourceContextMenu withExpectedSelectors:selectors];
}

- (void)testContextWithSelectedFolder
{
    RMResource *resource = [[RMResource alloc] init];
    resource.type = kCCBResTypeDirectory;

    ResourceContextMenu *resourceContextMenu = [[ResourceContextMenu alloc] initWithActionTarget:nil resources:@[resource]];

    NSArray *selectors = @[
            @"newFile:",
            @"newFolder:",
            @"showResourceInFinder:",
            @"createKeyFrameFromSelection:",
            @"openResourceWithExternalEditor:",
            @"deleteResource:",
            @"toggleSmartSheet:"];

    [self assertMenu:resourceContextMenu containsItemsWithSelectorNames:selectors];
    [self assertMenuItemsCount:resourceContextMenu withExpectedSelectors:selectors];
}


#pragma mark - test helper

- (void)assertMenuItemsCount:(ResourceContextMenu *)menu withExpectedSelectors:(NSArray *)selectors
{
    XCTAssertEqual([self countMenuItemsWithoutSeparators:menu], selectors.count, @"Mismatch of menu items expected %@ and found: %@",  selectors, [self menuItemsToString:menu]);
}

- (NSUInteger)countMenuItemsWithoutSeparators:(NSMenu *)menu
{
    NSUInteger result = 0;

    for (NSMenuItem *menuItem in [menu itemArray])
    {
        if (![menuItem isSeparatorItem])
        {
            result++;
        }
    }

    return result;
}

- (NSString *)menuItemsToString:(NSMenu *)menu
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSMenuItem *menuItem in [menu itemArray])
    {
        if ([menuItem isSeparatorItem])
        {
            continue;
        }

        if (menuItem.action)
        {
            [result addObject:NSStringFromSelector(menuItem.action)];
        }
        else
        {
            [result addObject:[NSString stringWithFormat:@"Empty action for: %@, %@",  menuItem, menuItem.title]];
        }
    }

    return [result description];
}

- (void)assertMenu:(NSMenu *)menu containsItemsWithSelectorNames:(NSArray *)selectorNames
{
    for (NSString *selectorName in selectorNames)
    {
        SEL sel = NSSelectorFromString(selectorName);
        XCTAssertTrue([self menu:menu containsItemWithSelector:sel], @"Menu does not contain menuitem with selector: \"%@\"", NSStringFromSelector(sel));
    }
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
