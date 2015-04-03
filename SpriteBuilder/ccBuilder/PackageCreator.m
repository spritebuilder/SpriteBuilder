#import "PackageCreator.h"
#import "NSError+SBErrors.h"
#import "NotificationNames.h"
#import "Errors.h"
#import "ProjectSettings.h"
#import "ProjectSettings+Packages.h"
#import "RMPackage.h"
#import "PackageSettings.h"

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

- (NSString *)createPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSString *fullPath = [_projectSettings fullPathForPackageName:packageName];

    if ([_projectSettings isPackageWithFullPathInProject:fullPath])
    {
        [NSError setNewErrorWithErrorPointer:error code:SBDuplicatePackageError message:[NSString stringWithFormat:@"Package %@ already in project", packageName]];
        return nil;
    }

    NSError *underlyingErrorCreate;
    BOOL createDirSuccess = [_fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:&underlyingErrorCreate];
    if (!createDirSuccess
        && underlyingErrorCreate.code == NSFileWriteFileExistsError)
    {
        [NSError setNewErrorWithErrorPointer:error
                                        code:SBPackageExistsButNotInProjectError
                                     message:[NSString stringWithFormat:@"Package %@ already exists on disk but is not in project", packageName]];
        return nil;
    }
    else if (!createDirSuccess)
    {
        [NSError setError:error withError:underlyingErrorCreate];
        return nil;
    }

    NSError *underlyingErrorAddResPath;
    BOOL addResPathSuccess = [_projectSettings addPackageWithFullPath:fullPath error:&underlyingErrorAddResPath];
    if(addResPathSuccess)
    {
        [self createPackageSettings:fullPath];

        [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED object:self];
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

    return [_projectSettings isPackageWithFullPathInProject:fullPath]
                    || [fileManager fileExistsAtPath:fullPath];
}

- (void)createPackageSettings:(NSString *)fullPath
{
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = fullPath;

    PackageSettings *packagePublishSettings = [[PackageSettings alloc] initWithPackage:package];
    [packagePublishSettings store];
}

@end
