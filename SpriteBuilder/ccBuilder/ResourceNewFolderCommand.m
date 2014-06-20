#import "ResourceNewFolderCommand.h"

#import "ResourceManager.h"
#import "RMResource.h"

@implementation ResourceNewFolderCommand

- (void)execute
{
    NSString *dirPath = [_resourceManager dirPathWithFirstDirFallbackForResource:_resources.firstObject];
    if (!dirPath)
    {
        return;
    }

    NSString *newDirPath = [self newUntitledFolderInDirPath:dirPath];

    [self selectAndMakeFolderEditable:dirPath newDirPath:newDirPath];
}

- (void)selectAndMakeFolderEditable:(NSString *)dirPath newDirPath:(NSString *)newDirPath
{
    RMResource *newResource = [_resourceManager resourceForPath:newDirPath];

    id parentResource = [_resourceManager resourceForPath:dirPath];
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
    [_resourceManager reloadAllResources];

    return newDirPath;
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