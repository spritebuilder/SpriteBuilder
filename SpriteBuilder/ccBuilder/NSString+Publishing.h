#import <Foundation/Foundation.h>

@interface NSString (Publishing)

// *** File methods

// Tests if the file actually exists in a resources-auto directoy
- (BOOL)isResourceAutoFile;

// Returns the resources-auto filepath of the file
- (NSString *)resourceAutoFilePath;

- (BOOL)isWaveSoundFile;

// Tests if the file has a spritesheet compatible extension (e.g. psd and png)
- (BOOL)isSmartSpriteSheetCompatibleFile;

// Returns all files in a resources-auto directory which is implicitely added and tested for the filename
- (NSArray *)filesInAutoDirectory;


// *** Directoy/Paths methods

// Returns all resolution dependant files in directory for given resolutions
- (NSArray *)resolutionDependantFilesInDirWithResolutions:(NSArray *)resolutions;

// Traverses recursively the directory and returns the latest date of all files found. Quite expensive operation.
- (NSDate *)latestModifiedDateOfPath;

// Shallow search for all files with the .png suffix and returns them
- (NSArray *)allPNGFilesInPath;

// Recursively tests if the path contains a file with a .ccb suffix
- (BOOL)containsCCBFile;

- (BOOL)isIntermediateFileLookup;
@end