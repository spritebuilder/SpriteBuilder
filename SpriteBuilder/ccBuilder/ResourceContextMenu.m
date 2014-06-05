#import "ResourceContextMenu.h"

#import "RMResource.h"
#import "ResourceTypes.h"
#import "RMDirectory.h"
#import "RMPackage.h"
#import "ResourceActionController.h"
#import "ResourceMenuItem.h"


@interface ResourceContextMenu ()

@property (nonatomic, strong, readwrite) id resource;
@property (nonatomic, strong, readwrite) NSArray *resources;

@end


@implementation ResourceContextMenu


#pragma mark - Initialization

// TODO: mixed selection support to show contextual menu items
// TODO: At least test first resource in array
- (instancetype)initWithResource:(id)resource actionController:(ResourceActionController *)actionController resources:(NSArray *)resources
{
    self = [super init];
    if (self)
    {
        self.resource = resource;
        self.resources = resources;
        self.actionController = actionController;

        [self setupMenu];
    }

    return self;
}

- (void)setupMenu
{
    [self removeAllItems];
    [self setAutoenablesItems:NO];

    [self appendItemToMenu:[self showInFinder] addSeparator:NO];
    [self appendItemToMenu:[self openInExternalEditor] addSeparator:YES];
    [self appendItemToMenu:[self toggleSmartSheet] addSeparator:YES];
    [self appendItemToMenu:[self createKeyFrames] addSeparator:YES];
    [self appendItemToMenu:[self newFile] addSeparator:NO];
    [self appendItemToMenu:[self newFolder] addSeparator:NO];
    [self appendItemToMenu:[self delete] addSeparator:YES];
    [self appendItemToMenu:[self exportTo] addSeparator:YES];

    [self removeLastItemIfSeparator];
}

- (NSMenuItem *)showInFinder
{
    if (_resources.count > 0)
    {
        return [self createMenuItemWithTitle:@"Show in Finder" selector:@selector(showResourceInFinder:)];
    }
    return nil;
}

- (NSMenuItem *)openInExternalEditor
{
    if ([_resource isKindOfClass:[RMResource class]]
       && [self isResourceCCBFileOrDirectory])
    {
        return [self createMenuItemWithTitle:@"Open with External Editor" selector:@selector(openResourceWithExternalEditor:)];
    }
    return nil;
}

- (NSMenuItem *)toggleSmartSheet
{
    if ([_resource isKindOfClass:[RMResource class]])
    {
        RMResource *clickedResource = _resource;
        if (clickedResource.type == kCCBResTypeDirectory)
        {
            RMDirectory *dir = clickedResource.data;
            NSString *title;
            if (dir.isDynamicSpriteSheet)
            {
                title = @"Remove Smart Sprite Sheet";
            }
            else
            {
                title = @"Make Smart Sprite Sheet";
            }

            return [self createMenuItemWithTitle:title selector:@selector(toggleSmartSheet:)];
        }
    }
    return nil;
}

- (NSMenuItem *)createKeyFrames
{
    if (_resources.count > 0)
    {
        return [self createMenuItemWithTitle:@"Create Keyframes from Selection" selector:@selector(createKeyFrameFromSelection:)];
    }
    return nil;
}

- (NSMenuItem *)newFile
{
    return [self createMenuItemWithTitle:@"New File..." selector:@selector(newFile:)];
}

- (NSMenuItem *)newFolder
{
    return [self createMenuItemWithTitle:@"New Folder" selector:@selector(newFolder:)];
}

- (NSMenuItem *)delete
{
    if ([_resource isKindOfClass:[RMResource class]]
        || (_resources.count > 0)
        || [_resource isKindOfClass:[RMPackage class]])
    {
        return [self createMenuItemWithTitle:@"Delete" selector:@selector(deleteResource:)];
    }
    return nil;

}

- (NSMenuItem *)exportTo
{
    if ([_resource isKindOfClass:[RMPackage class]])
    {
        return [self createMenuItemWithTitle:@"Export to..." selector:@selector(exportPackage:)];
    }
    return nil;
}

- (NSMenuItem *)createMenuItemWithTitle:(NSString *)title selector:(SEL)selector
{
    ResourceMenuItem *result = [[ResourceMenuItem alloc] initWithTitle:title selector:selector resources:_resources];
    [result setEnabled:YES];
    result.target = _actionController;
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

- (void)appendItemToMenu:(NSMenuItem *)item addSeparator:(BOOL)addSeparator
{
    if (item)
    {
        [self addItem:item];
    }

    if (item && addSeparator)
    {
        [self addItem:[NSMenuItem separatorItem]];
    }
}

- (BOOL)isResourceCCBFileOrDirectory
{
    RMResource *aResource = (RMResource *)_resource;
	return aResource.type == kCCBResTypeCCBFile || aResource.type == kCCBResTypeDirectory;
}

@end