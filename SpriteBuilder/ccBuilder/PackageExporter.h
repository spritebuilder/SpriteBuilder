#import <Foundation/Foundation.h>

@class ProjectSettings;
@class RMPackage;

@interface PackageExporter : NSObject

@property (nonatomic, weak) NSFileManager *fileManager;

// Returns the full path for an export of a package to a directory path
// Example: package.name is SuperPackage toPath is /foo/baa the export will be at /foo/baa/SuperPackage.sbpack
- (NSString *)exportPathForPackage:(RMPackage *)package toDirectoryPath:(NSString *)toDirectoryPath;

// Copies the package to a given path, the path exclude the packages name+extension.
// Returns NO if an error occured, check error object.
// Example: package.name is SuperPackage toDirectoryPath is /foo/baa the export will be at /foo/baa/SuperPackage.sbpack
- (BOOL)exportPackage:(RMPackage *)package toDirectoryPath:(NSString *)toDirectoryPath error:(NSError **)error;

@end