#import "PackageRenamer.h"
#import "NSString+Packages.h"
#import "RMPackage.h"
#import "SBErrors.h"
#import "NSError+SBErrors.h"
#import "ProjectSettings.h"
#import "ResourceManager.h"
#import "AppDelegate.h"

@implementation PackageRenamer

- (id)init
{
    self = [super init];
    if (self)
    {
        // default until we get some injection framework running
        self.fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (BOOL)renamePackage:(RMPackage *)package toName:(NSString *)newName error:(NSError **)error
{
    NSAssert(_projectSettings != nil, @"ProjectSetting must not be nil");
    NSAssert(_resourceManager != nil, @"ResourceManager must not be nil");

    NSString *newFullPath = [self fullPathForRenamedPackage:package toName:newName];

    if ([package.dirPath isEqualToString:newFullPath])
    {
        return YES;
    }

    NSString *oldFullPath = [package.dirPath copy];

    BOOL renameSuccessful = ([self canRenamePackage:package toName:newName error:error]
                            && [_fileManager moveItemAtPath:package.dirPath toPath:newFullPath error:error]
                            && [_projectSettings moveResourcePathFrom:package.dirPath toPath:newFullPath error:error]);

    if (renameSuccessful)
    {
        [_resourceManager setActiveDirectoriesWithFullReset:[_projectSettings absoluteResourcePaths]];
        [[AppDelegate appDelegate] renamedResourcePathFrom:oldFullPath toPath:newFullPath];
        return YES;
    }

    if (!*error)
    {
        [NSError setNewErrorWithCode:error code:SBRenamePackageGenericError message:[NSString stringWithFormat:@"An unexpected error occured. Code %li", SBRenamePackageGenericError]];
    }
    return NO;
}

- (BOOL)canRenamePackage:(RMPackage *)package toName:(NSString *)newName error:(NSError **)error
{
    NSString *newFullPath = [self fullPathForRenamedPackage:package toName:newName];

    if ([newFullPath isEqualToString:package.dirPath])
    {
        return YES;
    }

    if ([_projectSettings isResourcePathInProject:newFullPath])
    {
        [NSError setNewErrorWithCode:error code:SBDuplicateResourcePathError message:@"A package with this name already exists in the project"];
        return NO;
    }

    if ([_fileManager fileExistsAtPath:newFullPath])
    {
        [NSError setNewErrorWithCode:error code:SBResourcePathExistsButNotInProjectError message:@"A package with this name already exists on the file system, but is not in the project."];
        return NO;
    }

    return YES;
}

- (NSString *)fullPathForRenamedPackage:(RMPackage *)package toName:(NSString *)newName
{
    return [[package.dirPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[newName stringByAppendingPackageSuffix]];
}

@end