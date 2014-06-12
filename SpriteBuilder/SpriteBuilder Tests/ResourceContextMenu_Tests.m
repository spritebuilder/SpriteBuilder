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
#import "FeatureToggle.h"

@interface ResourceContextMenu_Tests : XCTestCase

@end


@implementation ResourceContextMenu_Tests

- (void)setUp
{
    [FeatureToggle sharedFeatures].packages = YES;
}

- (void)testContextWithEmptySelection
{
    ResourceContextMenu *resourceContextMenu = [[ResourceContextMenu alloc] initWithActionTarget:nil resources:@[]];

    NSArray *selectors = @[
            @"newFile:",
            @"newFolder:",
            @"newPackage:"];

    [self assertMenu:resourceContextMenu containsEnabledItemsWithSelectorNames:selectors];
    [self assertMenuItemsEnabledCount:resourceContextMenu withExpectedSelectors:selectors];
}

- (void)testContextWithSelectedImage
{
    RMResource *resource = [[RMResource alloc] init];
    resource.type = kCCBResTypeImage;

    ResourceContextMenu *resourceContextMenu = [[ResourceContextMenu alloc] initWithActionTarget:nil resources:@[resource]];

    NSArray *selectors = @[
            @"newFile:",
            @"newFolder:",
            @"openResourceWithExternalEditor:",
            @"showResourceInFinder:",
            @"createKeyFrameFromSelection:",
            @"deleteResource:"];

    [self assertMenu:resourceContextMenu containsEnabledItemsWithSelectorNames:selectors];
    [self assertMenuItemsEnabledCount:resourceContextMenu withExpectedSelectors:selectors];
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

    [self assertMenu:resourceContextMenu containsEnabledItemsWithSelectorNames:selectors];
    [self assertMenuItemsEnabledCount:resourceContextMenu withExpectedSelectors:selectors];
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
            @"deleteResource:",
            @"toggleSmartSheet:"];

    [self assertMenu:resourceContextMenu containsEnabledItemsWithSelectorNames:selectors];
    [self assertMenuItemsEnabledCount:resourceContextMenu withExpectedSelectors:selectors];
}

#pragma mark - test helper

- (void)assertMenuItemsEnabledCount:(ResourceContextMenu *)menu withExpectedSelectors:(NSArray *)selectors
{
    XCTAssertEqual([self countMenuItemsEnabledWithoutSeparators:menu], selectors.count, @"Mismatch of menu items expected %@ and found: %@",  selectors, [self menuItemsToString:menu]);
}

- (NSUInteger)countMenuItemsEnabledWithoutSeparators:(NSMenu *)menu
{
    NSUInteger result = 0;

    for (NSMenuItem *menuItem in [menu itemArray])
    {
        if (![menuItem isSeparatorItem] && menuItem.isEnabled)
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
            [result addObject:[NSString stringWithFormat:@"%@, enabled: %d",NSStringFromSelector(menuItem.action), menuItem.isEnabled]];
        }
        else
        {
            [result addObject:[NSString stringWithFormat:@"Empty action for: %@, %@",  menuItem, menuItem.title]];
        }
    }

    return [result description];
}

- (void)assertMenu:(NSMenu *)menu containsEnabledItemsWithSelectorNames:(NSArray *)selectorNames
{
    for (NSString *selectorName in selectorNames)
    {
        SEL sel = NSSelectorFromString(selectorName);
        XCTAssertTrue([self menu:menu containsEnabledItemWithSelector:sel], @"Menu does not contain enabled menuitem with selector: \"%@\"", NSStringFromSelector(sel));
    }
}

- (BOOL)menu:(NSMenu *)menu containsEnabledItemWithSelector:(SEL)selector
{
    NSArray *items = [menu itemArray];
    for (NSMenuItem *menuItem in items)
    {
        if (menuItem.action == selector && menuItem.isEnabled)
        {
            return YES;
        }
    }
    return NO;
}

@end
