#import "PackageCreator.h"
#import "NSError+SBErrors.h"
#import "NotificationNames.h"
#import "SBErrors.h"
#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"
#import "RMPackage.h"
#import "PackagePublishSettings.h"


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
    //NSImage* folderIcon = [NSImage imageNamed:@"Package.icns"];
    //[[NSWorkspace sharedWorkspace] setIcon:folderIcon forFile:packagePath options:0];
}

- (NSString *)createPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPath = [_projectSettings fullPathForPackageName:packageName];

    if ([_projectSettings isResourcePathInProject:fullPath])
    {
        [NSError setNewErrorWithCode:error code:SBDuplicateResourcePathError message:[NSString stringWithFormat:@"Package %@ already in project", packageName]];
        return nil;
    }

    NSError *underlyingErrorCreate;
    BOOL createDirSuccess = [_fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:&underlyingErrorCreate];
    if (!createDirSuccess
        && underlyingErrorCreate.code == NSFileWriteFileExistsError)
    {
        [NSError setNewErrorWithCode:error code:SBResourcePathExistsButNotInProjectError message:[NSString stringWithFormat:@"Package %@ already exists on disk but is not in project", packageName]];
        return nil;
    }
    else if (!createDirSuccess)
    {
        [NSError setError:error withError:underlyingErrorCreate];
        return nil;
    }

    NSError *underlyingErrorAddResPath;
    BOOL addResPathSuccess = [_projectSettings addResourcePath:fullPath error:&underlyingErrorAddResPath];
    if(addResPathSuccess)
    {
        [self addIconToPackageFile:fullPath];

        [self createPackageSettings:fullPath];

        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:nil];
        return fullPath;
    }

    [NSError setError:error withError:underlyingErrorAddResPath];
    return nil;
}

- (NSString *)creatablePackageNameWithBaseName:(NSString *)baseName
{
    NSString *currentBaseName = baseName;
    NSUInteger counter = 1;
    while([self isBaseNameInProjectOrExistsOnFilesystem:currentBaseName])
    {
        currentBaseName = [NSString stringWithFormat:@"%@ %lu", baseName, counter];
        counter++;
    }

    return currentBaseName;
}

- (BOOL)isBaseNameInProjectOrExistsOnFilesystem:(NSString *)baseName
{
    NSString *fullPath = [_projectSettings fullPathForPackageName:baseName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    return [_projectSettings isResourcePathInProject:fullPath]
                    || [fileManager fileExistsAtPath:fullPath];
}

- (void)createPackageSettings:(NSString *)fullPath
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = fullPath;

    PackagePublishSettings *packagePublishSettings = [[PackagePublishSettings alloc] initWithPackage:package];
    [packagePublishSettings store];
}

@end