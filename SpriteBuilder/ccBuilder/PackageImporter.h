#import <Foundation/Foundation.h>

@class ProjectSettings;

@interface PackageImporter : NSObject

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSFileManager *fileManager;

// Will import a package by name. The package name has to contain the PACKAGE_NAME_SUFFIX.
// The package has to be at the root level of the project directory.
// Sends RESOURCE_PATHS_CHANGED notification after package has been added successfully.
// Returns NO if there was an error.
- (BOOL)importPackageWithName:(NSString *)packageName error:(NSError **)error;

// Will import an array of package paths. All package names have to contain the PACKAGE_NAME_SUFFIX.
// Everything that is not a package path is ignored
// Sends RESOURCE_PATHS_CHANGED notification after all packages
// have been added. Notification only sent if there is at least one succesfully added package.
// Returns NO if there were errors. Will try to add all packages given, won't exit prematurely on error
// In error's userInfo dictionary there'll be the "errors" key with all underlying errors
- (BOOL)importPackagesWithPaths:(NSArray *)packagePaths error:(NSError **)error;

@end