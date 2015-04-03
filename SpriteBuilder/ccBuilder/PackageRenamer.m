#import "PackageRenamer.h"
#import "NSString+Packages.h"
#import "RMPackage.h"
#import "Errors.h"
#import "NSError+SBErrors.h"
#import "ProjectSettings.h"
#import "ResourceManager.h"
#import "AppDelegate.h"
#import "NSString+Misc.h"
#import "NotificationNames.h"

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
                            && [_projectSettings movePackageWithFullPathFrom:package.dirPath toFullPath:newFullPath error:error]);

    if (renameSuccessful)
    {
        [_resourceManager setActiveDirectoriesWithFullReset:[_projectSettings absolutePackagePaths]];
        [[AppDelegate appDelegate] renamedResourcePathFrom:oldFullPath toPath:newFullPath];
        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:package];
        return YES;
    }

    if (!*error)
    {
        [NSError setNewErrorWithErrorPointer:error code:SBRenamePackageGenericError message:[NSString stringWithFormat:@"An unexpected error occured. Code %li", SBRenamePackageGenericError]];
    }
    return NO;
}

- (BOOL)canRenamePackage:(RMPackage *)package toName:(NSString *)newName error:(NSError **)error
{
    NSString *newFullPath = [self fullPathForRenamedPackage:package toName:newName];

    if (!newName || [newName isEmpty])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBEmptyPackageNameError message:@"A package name must not be empty or consist of whitespace characters only"];
        return NO;
    }

    if ([newFullPath isEqualToString:package.dirPath])
    {
        return YES;
    }

    if ([_projectSettings isPackageWithFullPathInProject:newFullPath])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBDuplicatePackageError message:@"A package with this name already exists in the project"];
        return NO;
    }

    if ([_fileManager fileExistsAtPath:newFullPath])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBPackageExistsButNotInProjectError message:@"A package with this name already exists on the file system, but is not in the project."];
        return NO;
    }

    return YES;
}

- (NSString *)fullPathForRenamedPackage:(RMPackage *)package toName:(NSString *)newName
{
    return [[package.dirPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[newName stringByAppendingPackageSuffix]];
}

@end