#import "ResourceOpenInExternalEditorCommand.h"

#import "RMResource.h"
#import "RMDirectory.h"
#import "ResourceTypes.h"

@implementation ResourceOpenInExternalEditorCommand

- (void)execute
{
    RMResourceBase *resource = _resources.firstObject;

    NSString *path = [resource fullPath];
    if (path)
    {
        [[NSWorkspace sharedWorkspace] openFile:path];
    }
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
	return aResource.type != kCCBResTypeCCBFile && aResource.type != kCCBResTypeDirectory;
}

@end