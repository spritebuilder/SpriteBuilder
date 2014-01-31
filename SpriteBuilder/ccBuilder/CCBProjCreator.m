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

-(BOOL) createDefaultProjectAtPath:(NSString*)fileName engine:(CCBTargetEngine)engine
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
	NSString* substitutableProjectName = @"PROJECTNAME";
	if (engine == CCBTargetEngineSpriteKit)
	{
		substitutableProjectName = [NSString stringWithFormat:@"SPRITEKIT%@", substitutableProjectName];
	}
	
    NSString* zipFile = [[NSBundle mainBundle] pathForResource:substitutableProjectName ofType:@"zip" inDirectory:@"Generated"];
    
    // Check that zip file exists
    if (![fm fileExistsAtPath:zipFile])
    {
        [[AppDelegate appDelegate] modalDialogTitle:@"Failed to Create Project"
											message:@"The default SpriteBuilder project is missing from this build. Make sure that you build SpriteBuilder using 'Scripts/BuildDistribution.sh <versionstr>' the first time you build the program."];
        return NO;
    }
    
    // Unzip resources
    NSTask* zipTask = [[NSTask alloc] init];
    [zipTask setCurrentDirectoryPath:[fileName stringByDeletingLastPathComponent]];
    [zipTask setLaunchPath:@"/usr/bin/unzip"];
    NSArray* args = [NSArray arrayWithObjects:@"-o", zipFile, nil];
    [zipTask setArguments:args];
    [zipTask launch];
    [zipTask waitUntilExit];
    
    // Rename ccbproj
	NSString* ccbproj = [NSString stringWithFormat:@"%@.ccbproj", substitutableProjectName];
    [fm moveItemAtPath:[[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:ccbproj] toPath:fileName error:NULL];
    
    // Update the Xcode project
	NSString* xcodeproj = [NSString stringWithFormat:@"%@.xcodeproj", substitutableProjectName];
    NSString* xcodeFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:xcodeproj];
    NSString* projName = [[fileName lastPathComponent] stringByDeletingPathExtension];
    
    // Update the project
    [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:@"project.pbxproj"] projectName:substitutableProjectName];
    
    // Update workspace data
    [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:@"project.xcworkspace/contents.xcworkspacedata"] projectName:substitutableProjectName];
    
    // Update scheme
	NSString* xcscheme = [NSString stringWithFormat:@"xcshareddata/xcschemes/%@.xcscheme", substitutableProjectName];
    [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:xcscheme] projectName:substitutableProjectName];
    
    // Rename scheme file
    NSString* schemeFile = [xcodeFileName stringByAppendingPathComponent:xcscheme];
    NSString* newSchemeFile = [[[schemeFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"xcscheme"];
    [fm moveItemAtPath:schemeFile toPath:newSchemeFile error:NULL];
    
    // Rename Xcode project file
    NSString* newXcodeFileName = [[[xcodeFileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"xcodeproj"];
    
    [fm moveItemAtPath:xcodeFileName toPath:newXcodeFileName error:NULL];
    
    // Rename Approj project file (apportable)
    NSString* approjFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"PROJECTNAME.approj"];
    projName = [[fileName lastPathComponent] stringByDeletingPathExtension];

    NSString* newApprojFileName = [[[approjFileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"approj"];
    [fm moveItemAtPath:approjFileName toPath:newApprojFileName error:NULL];

    // configure default configuration.json and include opengles2 as a feature
    NSError *error = nil;
    NSString *apportableConfigFile = [NSString stringWithFormat:@"%@%@", newApprojFileName, @"/configuration.json"];
    NSString *apportableConfigurationContents = [NSString stringWithContentsOfFile:apportableConfigFile encoding:NSUTF8StringEncoding error:&error];
    
    NSString *replacement = [NSString stringWithFormat:@"\"default_target\": {\"project\": \"%@\", \"project_config\": \"Release\", \"target\": \"%@\"},", projName, projName];
    apportableConfigurationContents = [apportableConfigurationContents stringByReplacingOccurrencesOfString:@"default_target" withString:replacement];
    [apportableConfigurationContents writeToFile:apportableConfigFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    return [fm fileExistsAtPath:fileName];
}

- (void) setName:(NSString*)name inFile:(NSString*)fileName projectName:(NSString*)projectName
{
    NSString* regExp = [NSString stringWithFormat:@"s/%@/%@/g", projectName, name];
    
	@try {
		NSTask* renameTask = [[NSTask alloc] init];
		[renameTask setCurrentDirectoryPath:[fileName stringByDeletingLastPathComponent]];
		[renameTask setLaunchPath:@"/usr/bin/sed"];
		NSArray* args = [NSArray arrayWithObjects:@"-ie", regExp, fileName, nil];
		NSLog(@"ARGS: %@", args);
		[renameTask setArguments:args];
		[renameTask launch];
		[renameTask waitUntilExit];
	}
	@catch (NSException *exception) {
		NSLog(@"ERROR CREATING PROJECT: %@", exception);
		NSLog(@"working dir: %@", [fileName stringByDeletingLastPathComponent]);
		[exception raise];
	}
	@finally {
	}
}


@end
