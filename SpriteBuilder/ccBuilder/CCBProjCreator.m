//
//  CCBProjCreator.m
//  SpriteBuilder
//
//  Created by Viktor on 10/11/13.
//
//

#import "CCBProjCreator.h"
#import "AppDelegate.h"

@implementation CCBProjCreator

- (BOOL) createDefaultProjectAtPath:(NSString*)fileName
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSString* zipFile = [[NSBundle mainBundle] pathForResource:@"PROJECTNAME" ofType:@"zip" inDirectory:@"Generated"];
    
    // Check that zip file exists
    if (![fm fileExistsAtPath:zipFile])
    {
        [[AppDelegate appDelegate] modalDialogTitle:@"Failed to Create Project" message:@"The default SpriteBuilder project is missing from this build. Make sure that you build SpriteBuilder using 'Scripts/BuildDistribution.sh <versionstr>' the first time you build the program."];
        return NO;
    }
    
    // Unzip resources
    NSTask* zipTask = [[NSTask alloc] init];
    [zipTask setCurrentDirectoryPath:[fileName stringByDeletingLastPathComponent]];
    [zipTask setLaunchPath:@"/usr/bin/unzip"];
    NSArray* args = [NSArray arrayWithObjects:zipFile, nil];
    [zipTask setArguments:args];
    [zipTask launch];
    [zipTask waitUntilExit];
    [zipTask release];
    
    // Rename ccbproj
    [fm moveItemAtPath:[[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"PROJECTNAME.ccbproj"] toPath:fileName error:NULL];
    
    // Update the Xcode project
    NSString* xcodeFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"PROJECTNAME.xcodeproj"];
    NSString* projName = [[fileName lastPathComponent] stringByDeletingPathExtension];
    
    //[self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:@"project.pbxproj"]];
    
    NSString* newXcodeFileName = [[[xcodeFileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"xcodeproj"];
    
    // Rename Xcode project
    //[fm moveItemAtPath:xcodeFileName toPath:newXcodeFileName error:NULL];
    
    return [fm fileExistsAtPath:fileName];
}

- (void) setName:(NSString*) name inFile:(NSString*)fileName
{
    NSString* regExp = [NSString stringWithFormat:@"'s/PROJECTNAME/%@/g'", name];
    
    NSTask* renameTask = [[NSTask alloc] init];
    [renameTask setCurrentDirectoryPath:[fileName stringByDeletingLastPathComponent]];
    [renameTask setLaunchPath:@"/usr/bin/sed"];
    NSArray* args = [NSArray arrayWithObjects:@"-i", regExp, fileName, nil];
    [renameTask setArguments:args];
    [renameTask launch];
    [renameTask waitUntilExit];
    [renameTask release];
}


@end
