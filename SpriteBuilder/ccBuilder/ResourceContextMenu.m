#import "ResourceContextMenu.h"

#import "RMResource.h"
#import "ResourceTypes.h"
#import "RMDirectory.h"
#import "RMPackage.h"
#import "ResourceCommandController.h"
#import "ResourceShowInFinderCommand.h"
#import "ResourceOpenInExternalEditorCommand.h"
#import "ResourceToggleSmartSpriteSheetCommand.h"
#import "ResourceCreateKeyframesCommand.h"
#import "ResourceNewFileCommand.h"
#import "ResourceNewFolderCommand.h"
#import "ResourceNewPackageCommand.h"
#import "ResourceDeleteCommand.h"
#import "ResourceExportPackageCommand.h"
#import "FeatureToggle.h"


@interface ResourceContextMenu ()

@property (nonatomic, strong, readwrite) NSArray *resources;
@property (nonatomic, weak) id actionTarget;

@end


@implementation ResourceContextMenu


#pragma mark - Initialization

- (instancetype)initWithActionTarget:(id)actionTarget resources:(NSArray *)resources
{
    self = [super init];
    if (self)
    {
        self.resources = resources;
        self.actionTarget = actionTarget;

        [self setupMenu];
    }

    return self;
}

- (void)setupMenu
{
    [self removeAllItems];
    [self setAutoenablesItems:NO];

    [self appendItemToMenuWithClass:[ResourceShowInFinderCommand class] addSeparator:NO action:@selector(showResourceInFinder:)];
    [self appendItemToMenuWithClass:[ResourceOpenInExternalEditorCommand class] addSeparator:YES action:@selector(openResourceWithExternalEditor:)];
    [self appendItemToMenuWithClass:[ResourceToggleSmartSpriteSheetCommand class] addSeparator:YES action:@selector(toggleSmartSheet:)];
    [self appendItemToMenuWithClass:[ResourceCreateKeyframesCommand class] addSeparator:YES action:@selector(createKeyFrameFromSelection:)];
    [self appendItemToMenuWithClass:[ResourceNewFileCommand class] addSeparator:NO action:@selector(newFile:)];
    [self appendItemToMenuWithClass:[ResourceNewFolderCommand class] addSeparator:NO action:@selector(newFolder:)];
    [self appendItemToMenuWithClass:[ResourceNewPackageCommand class] addSeparator:NO action:@selector(newPackage:)];
    [self appendItemToMenuWithClass:[ResourceDeleteCommand class] addSeparator:YES action:@selector(deleteResource:)];

    if ([FeatureToggle sharedFeatures].arePackagesEnabled)
    {
        [self appendItemToMenuWithClass:[ResourceExportPackageCommand class] addSeparator:NO action:@selector(exportPackage:)];
    }

    [self removeLastItemIfSeparator];
}

- (void)appendItemToMenuWithClass:(Class)aClass addSeparator:(BOOL)addSeparator action:(SEL)action
{
    if ([aClass conformsToProtocol:@protocol(ResourceCommandContextMenuProtocol)])
    {
        NSString *name = [aClass performSelector:@selector(nameForResources:) withObject:_resources];
        NSMenuItem *menuItem = [self createMenuItemWithTitle:name selector:action];
        [self addItem:menuItem];

        BOOL isValid = [[aClass performSelector:@selector(isValidForSelectedResources:) withObject:_resources] boolValue];
        [menuItem setEnabled:isValid];

        if (addSeparator)
        {
            [self addItem:[NSMenuItem separatorItem]];
        }
    }
}

- (NSMenuItem *)createMenuItemWithTitle:(NSString *)title selector:(SEL)selector
{
    NSMenuItem *result = [[NSMenuItem alloc] initWithTitle:title action:selector keyEquivalent:@""];
    [result setEnabled:YES];
    result.target = _actionTarget;
    return result;
}

- (void)removeLastItemIfSeparator
{
    NSMenuItem *item = [self itemAtIndex:[self numberOfItems]-1];
    if ([item isSeparatorItem])
    {
        [self removeItem:item];
    }
}

@end