#import <Foundation/Foundation.h>

@class ProjectSettings;


@interface PackageCreator : NSObject

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSFileManager *fileManager;

// Creates a package at the root level of the project directory. A package is a special folder.
// A suffix defined in PACKAGE_NAME_SUFFIX is added to the folder name.
// Sends RESOURCE_PATHS_CHANGED notification after package has been added successfully.
// Returns the full path else nil if there was an error.
- (NSString *)createPackageWithName:(NSString *)packageName error:(NSError **)error;

// Searches for a package name that can be created
// Example: baseName is foo, package "foo" already exists (on disk or in project), result would be "foo 1"
- (NSString *)creatablePackageNameWithBaseName:(NSString *)baseName;

@end