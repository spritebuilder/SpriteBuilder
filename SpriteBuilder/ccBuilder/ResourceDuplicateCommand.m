//
//  ResourceDuplicateCommand.m
//  SpriteBuilder
//
//  Created by Martin Walsh on 30/10/2014.
//
//

#import "ResourceDuplicateCommand.h"

#import "ResourceManager.h"
#import "RMResource.h"

@implementation ResourceDuplicateCommand

- (void)execute
{
    RMResource *resource = _resources.firstObject;

    NSAssert(resource.type== kCCBResTypeSBFile,@"Only CCB files currently supported for duplication.");

     [self duplicateResource:resource];
}

- (void)duplicateResource:(RMResource*) res {

    NSFileManager* fm = [NSFileManager defaultManager];
    NSError* error = nil;

    NSString* path     = [res.filePath stringByDeletingLastPathComponent];
    NSString* baseName = [[res.filePath lastPathComponent] stringByDeletingPathExtension];
    NSString* ext  = [res.filePath pathExtension];

    uint copyId = 1;
    NSString *targetName = [NSString stringWithFormat:@"%@ copy %d.%@",
                            baseName, copyId, ext];
    NSString *targetPath = [path stringByAppendingPathComponent:targetName];

    // Ensure Unique Copy
    while ([fm fileExistsAtPath:targetPath]) {
        targetName = [NSString stringWithFormat:@"%@ copy %d.%@",
                      baseName, ++copyId, ext];
        targetPath = [path stringByAppendingPathComponent:targetName];
    }

    if(![fm copyItemAtPath:res.filePath toPath:targetPath error:&error]) {
        NSLog(@"%@",error);
    }

    // Refresh
    [[ResourceManager sharedManager] reloadAllResources];
}

#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"Duplicate File";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    id firstResource = resources.firstObject;
    if ([firstResource isKindOfClass:[RMResource class]])
    {
        RMResource *clickedResource = firstResource;
        if (clickedResource.type == kCCBResTypeSBFile)
        {
            return YES;
        }
    }
    return NO;
}

@end
