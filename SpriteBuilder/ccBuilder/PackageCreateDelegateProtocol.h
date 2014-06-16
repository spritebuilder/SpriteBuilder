#import <Foundation/Foundation.h>

@protocol PackageCreateDelegateProtocol <NSObject>

// Creates a package at the root level of the project directory. A package is a special folder.
// A suffix defined in PACKAGE_NAME_SUFFIX is added to the folder name.
// Sends RESOURCE_PATHS_CHANGED notification after package has been added successfully.
// Returns NO if there was an error.
- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error;

// Will import a package by name. The package name has to contain the PACKAGE_NAME_SUFFIX.
// The package has to be at the root level of the project directory.
// Sends RESOURCE_PATHS_CHANGED notification after package has been added successfully.
// Returns NO if there was an error.
- (BOOL)importPackageWithName:(NSString *)packageName error:(NSError **)error;

@end