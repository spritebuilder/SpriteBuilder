#import <Foundation/Foundation.h>

@class ProjectSettings;
@class RMPackage;

@interface PackageExporter : NSObject

@property (nonatomic, weak) NSFileManager *fileManager;

// Copies the package to a given path
// Returns NO if an error occured, check error object.
- (BOOL)exportPackage:(RMPackage *)package toPath:(NSString *)toPath error:(NSError **)error;

@end