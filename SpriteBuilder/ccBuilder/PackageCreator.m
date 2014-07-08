#import "PackageCreator.h"
#import "NSError+SBErrors.h"
#import "NotificationNames.h"
#import "SBErrors.h"
#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"


@implementation PackageCreator

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

- (void)addIconToPackageFile:(NSString *)packagePath
{
    NSImage* folderIcon = [NSImage imageNamed:@"Package.icns"];
    [[NSWorkspace sharedWorkspace] setIcon:folderIcon forFile:packagePath options:0];
}

- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPath = [_projectSettings fullPathForPackageName:packageName];

    if ([_projectSettings isResourcePathInProject:fullPath])
    {
        [NSError setNewErrorWithCode:error code:SBDuplicateResourcePathError message:[NSString stringWithFormat:@"Package %@ already in project", packageName]];
        return NO;
    }

    NSError *underlyingErrorCreate;
    BOOL createDirSuccess = [_fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:&underlyingErrorCreate];
    if (!createDirSuccess
        && underlyingErrorCreate.code == NSFileWriteFileExistsError)
    {
        [NSError setNewErrorWithCode:error code:SBResourcePathExistsButNotInProjectError message:[NSString stringWithFormat:@"Package %@ already in project", packageName]];
        return NO;
    }
    else if (!createDirSuccess)
    {
        [NSError setError:error withError:underlyingErrorCreate];
        return NO;
    }

    NSError *underlyingErrorAddResPath;
    BOOL addResPathSuccess = [_projectSettings addResourcePath:fullPath error:&underlyingErrorAddResPath];
    if(addResPathSuccess)
    {
        [self addIconToPackageFile:fullPath];

        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
        return YES;
    }

    [NSError setError:error withError:underlyingErrorAddResPath];
    return NO;
}

@end