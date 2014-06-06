#import "ResourceNewFolderCommand.h"

#import "ResourceManager.h"
#import "RMResource.h"
#import "ResourceTypes.h"
#import "RMDirectory.h"


@implementation ResourceNewFolderCommand

- (void)execute
{
    NSString *dirPath = [self dirPathWithFirstDirFallbackForResource:_resources.firstObject];
    if (!dirPath)
    {
        return;
    }

    NSString *newDirPath = [self newUntitledFolderInDirPath:dirPath];

    [self selectAndMakeFolderEditable:dirPath newDirPath:newDirPath];
}

- (void)selectAndMakeFolderEditable:(NSString *)dirPath newDirPath:(NSString *)newDirPath
{
    RMResource *newResource = [[ResourceManager sharedManager] resourceForPath:newDirPath];

    id parentResource = [[ResourceManager sharedManager] resourceForPath:dirPath];
    [_outlineView expandItem:parentResource];
    [_outlineView editColumn:0 row:[_outlineView rowForItem:newResource] withEvent:nil select:YES];
}

- (NSString *)newUntitledFolderInDirPath:(NSString *)dirPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    int attempt = 0;
    NSString *newDirPath = NULL;
    while (newDirPath == NULL)
    {
        NSString *dirName = NULL;
        if (attempt == 0)
        {
            dirName = @"Untitled Folder";
        }
        else
        {
            dirName = [NSString stringWithFormat:@"Untitled Folder %d", attempt];
        }

        newDirPath = [dirPath stringByAppendingPathComponent:dirName];

        if ([fileManager fileExistsAtPath:newDirPath])
        {
            attempt++;
            newDirPath = NULL;
        }
    }

    [fileManager createDirectoryAtPath:newDirPath withIntermediateDirectories:YES attributes:NULL error:NULL];
    [[ResourceManager sharedManager] reloadAllResources];

    return newDirPath;
}

- (NSString *)dirPathWithFirstDirFallbackForResource:(id)resource
{
    NSString *dirPath = [self dirPathForResource:resource];

    // Find directory
    NSArray *dirs = [ResourceManager sharedManager].activeDirectories;
    if (dirs.count == 0)
    {
        return nil;
    }

    RMDirectory *dir = [dirs objectAtIndex:0];
    if (!dirPath)
    {
        dirPath = dir.dirPath;
    }
    return dirPath;
}

- (NSString *)dirPathForResource:(id)resource
{
    NSString *dirPath;
    if ([resource isKindOfClass:[RMDirectory class]])
    {
        RMDirectory *directoryResource = (RMDirectory *) resource;
        dirPath = directoryResource.dirPath;

    }
    else if ([resource isKindOfClass:[RMResource class]])
    {
        RMResource *aResource = (RMResource *) resource;
        if (aResource.type == kCCBResTypeDirectory)
        {
            dirPath = aResource.filePath;
        }
        else
        {
            dirPath = [aResource.filePath stringByDeletingLastPathComponent];
        }
    }
    return dirPath;
}


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"New Folder";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return YES;
}

@end