#import <Foundation/Foundation.h>

@protocol PackageCreateDelegateProtocol;
@class ProjectSettings;


@interface PackageController : NSObject <PackageCreateDelegateProtocol>

@property (nonatomic, strong) ProjectSettings *projectSettings;
@property (nonatomic, strong) NSFileManager *fileManager;

- (void)showCreateNewPackageDialogForWindow:(NSWindow *)window;


#pragma mark - PackageCreateDelegateProtocol

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

// Will import an package with a full path. Sends RESOURCE_PATHS_CHANGED notification after package has been added
// Notification only sent if package was added succesfully.
// Returns NO if there was an error
- (BOOL)importPackageWithPath:(NSString *)packagePath error:(NSError **)error;

// Will import an array of package paths. All package names have to contain the PACKAGE_NAME_SUFFIX.
// Sends RESOURCE_PATHS_CHANGED notification after all packages
// have been added. Notification only sent if there is at least one succesfully added package.
// Returns NO if there were errors. Will try to add all packages given, won't exit prematurely on error
// In error's userInfo dictionary there'll be the "errors" key with all underlying errors
- (BOOL)importPackagesWithPaths:(NSArray *)packagePaths error:(NSError **)error;

// Will remove package paths from the project, it won't delete the folders just the project reference
// All package names have to contain the PACKAGE_NAME_SUFFIX.
// Sends RESOURCE_PATHS_CHANGED notification if there is at least one package that was removed successfully.
// Returns NO if there was at least one error.
// In error's userInfo dictionary there'll be the "errors" key with all underlying errors
- (BOOL)removePackagesFromProject:(NSArray *)packagePaths error:(NSError **)error;

@end