#import "PackageExporter.h"
#import "RMPackage.h"
#import "SBErrors.h"
#import "NSError+SBErrors.h"

@implementation PackageExporter

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

- (BOOL)exportPackage:(RMPackage *)package toPath:(NSString *)toPath error:(NSError **)error
{
    if ([self isPackageValid:package])
    {
        [NSError setNewErrorWithCode:error code:SBPackageExportInvalidPackageError message:[NSString stringWithFormat:@"Internal error: Invalid package %@ given.", package]];
        return NO;
    }

    NSString *copyToPath = [toPath stringByAppendingPathComponent:[package.dirPath lastPathComponent]];

    if ([_fileManager fileExistsAtPath:copyToPath])
    {
        *error = [NSError errorWithDomain:SBErrorDomain
                                     code:SBPackageAlreadyExistsAtPathError
                                 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Package %@ already exists at path %@.", package, toPath]}];
        return NO;
    }

    return [_fileManager copyItemAtPath:package.dirPath toPath:copyToPath error:error];
}

- (BOOL)isPackageValid:(RMPackage *)package
{
    return !package
        || ![package isKindOfClass:[RMPackage class]]
        || !package.dirPath;
}

@end