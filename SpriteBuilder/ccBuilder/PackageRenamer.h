#import <Foundation/Foundation.h>

@class ProjectSettings;
@class RMPackage;
@class ResourceManager;

@interface PackageRenamer : NSObject

@property (nonatomic, weak) ProjectSettings *projectSettings;
@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) ResourceManager *resourceManager;

// Renames a package, provide the package and a name not containing the .PACKAGE_NAME_SUFFIX
// Returns NO if an error occured, check error object for reasons.
- (BOOL)renamePackage:(RMPackage *)package toName:(NSString *)newName error:(NSError **)error;

// Tests if a given package can be renamed to the given name.
// Name should not contain the .PACKAGE_NAME_SUFFIX
// Returns NO if an error occured, check error object for reasons.
- (BOOL)canRenamePackage:(RMPackage *)aPackage toName:(NSString *)newName error:(NSError **)error;

@end