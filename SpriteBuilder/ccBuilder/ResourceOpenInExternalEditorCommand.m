#import "ResourceOpenInExternalEditorCommand.h"
#import "RMResource.h"
#import "RMDirectory.h"
#import "ResourceTypes.h"


@implementation ResourceOpenInExternalEditorCommand

- (void)execute
{
    NSString *path = [self getPathOfResource:_resources.firstObject];
    if (path)
    {
        [[NSWorkspace sharedWorkspace] openFile:path];
    }
}

- (NSString *)getPathOfResource:(id)resource
{
    if (!resource)
    {
        return nil;
    }

    NSString *fullPath;
    if ([resource isKindOfClass:[RMDirectory class]])
    {
        fullPath = ((RMDirectory *) resource).dirPath;
    }
    else if ([resource isKindOfClass:[RMResource class]])
    {
        fullPath = ((RMResource *) resource).filePath;
    }

    // if it doesn't exist, peek inside "resources-auto" (only needed in the case of resources, which has a different visual
    // layout than what is actually on the disk).
    // Should probably be removed and pulled into [RMResource filePath]
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath] == NO)
    {
        NSString *filename = [fullPath lastPathComponent];
        NSString *directory = [fullPath stringByDeletingLastPathComponent];
        fullPath = [NSString pathWithComponents:[NSArray arrayWithObjects:directory, @"resources-auto", filename, nil]];
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath] == NO)
    {
        return nil;
    }

    return fullPath;
}


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"Open with External Editor";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return ([resources.firstObject isKindOfClass:[RMResource class]]
       && [[self class] isResourceCCBFileOrDirectory:resources.firstObject]);
}

+ (BOOL)isResourceCCBFileOrDirectory:(id)resource
{
    RMResource *aResource = (RMResource *)resource;
	return aResource.type == kCCBResTypeCCBFile || aResource.type == kCCBResTypeDirectory;
}

@end