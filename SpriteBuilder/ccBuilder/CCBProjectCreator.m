//
//  CCBProjectCreator.m
//  SpriteBuilder
//
//  Created by Viktor on 10/11/13.
//
//

#import "CCBProjectCreator.h"
#import "AppDelegate.h"


@implementation NSString (IdentifierSanitizer)

- (NSString *)sanitizedIdentifier
{
    NSString* identifier = [self stringByTrimmingCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
    NSMutableString* sanitized = [NSMutableString new];
    
    for (int idx = 0; idx < [identifier length]; idx++)
    {
        unichar ch = [identifier characterAtIndex:idx];
        if (!isalpha(ch))
        {
            ch = '_';
        }
        [sanitized appendString:[NSString stringWithCharacters:&ch length:1]];
    }
    
    NSString *trimmed = [sanitized stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_"]];
    if ([trimmed length] == 0)
    {
        trimmed = @"identifier";
    }
    
    return trimmed;
}

@end

@implementation CCBProjectCreator

-(BOOL) createDefaultProjectAtPath:(NSString*)fileName engine:(CCBTargetEngine)engine
{
    NSError *error = nil;
    NSFileManager* fm = [NSFileManager defaultManager];
    
	NSString* substitutableProjectName = @"PROJECTNAME";
    NSString* substitutableProjectIdentifier = @"PROJECTIDENTIFIER";
    
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
    NSString* identifier = [projName sanitizedIdentifier];
    
    // Update the project
    [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:@"project.pbxproj"] search:substitutableProjectName];
    [self setName:identifier inFile:[xcodeFileName stringByAppendingPathComponent:@"project.pbxproj"] search:substitutableProjectIdentifier];
    
    // Update workspace data
    [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:@"project.xcworkspace/contents.xcworkspacedata"] search:substitutableProjectName];
    
    // Update scheme
	NSString* xcscheme = [NSString stringWithFormat:@"xcshareddata/xcschemes/%@ iOS.xcscheme", substitutableProjectName];
	[self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:xcscheme] search:substitutableProjectName];
	
	
    NSString* androidXcscheme = [NSString stringWithFormat:@"xcshareddata/xcschemes/%@ Android.xcscheme", substitutableProjectName];
    [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:androidXcscheme] search:substitutableProjectName];
    
    // Rename scheme file
	//iOS
	{
    NSString* schemeFile = [xcodeFileName stringByAppendingPathComponent:xcscheme];
		NSString* newSchemeFile = [[[[schemeFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingString:@" iOS" ] stringByAppendingPathExtension:@"xcscheme"];
		[fm moveItemAtPath:schemeFile toPath:newSchemeFile error:NULL];
    }
	
	//Android
	{
		NSString* schemeFile = [xcodeFileName stringByAppendingPathComponent:androidXcscheme];
		NSString* newSchemeFile = [[[[schemeFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingString:@" Android" ] stringByAppendingPathExtension:@"xcscheme"];
    [fm moveItemAtPath:schemeFile toPath:newSchemeFile error:NULL];
    }
    
    // Rename Xcode project file
    NSString* newXcodeFileName = [[[xcodeFileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"xcodeproj"];
    
    [fm moveItemAtPath:xcodeFileName toPath:newXcodeFileName error:NULL];
    
    // Rename Approj project file (apportable)
    NSString* approjFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"PROJECTNAME.approj"];
    projName = [[fileName lastPathComponent] stringByDeletingPathExtension];

    NSString* newApprojFileName = [[[approjFileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"approj"];
    [fm moveItemAtPath:approjFileName toPath:newApprojFileName error:NULL];

    /// SBPRO
    NSString* activityJavaFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/java/org/cocos2d/%@/%@Activity.java", substitutableProjectIdentifier, substitutableProjectIdentifier]];
    if ([fm fileExistsAtPath:activityJavaFileName])
    {
        NSString* resultActivityJavaFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/java/org/cocos2d/%@/%@Activity.java", identifier, identifier]];
        
        if (![fm createDirectoryAtPath:[resultActivityJavaFileName stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]) {
            return NO;
        }
        
        if (![fm moveItemAtPath:activityJavaFileName toPath:resultActivityJavaFileName error:&error]) {
            return NO;
        }
        [self setName:identifier inFile:resultActivityJavaFileName search:substitutableProjectIdentifier];
        
        NSString* activityMFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/%@Activity.m", substitutableProjectIdentifier]];
        NSString* resultActivityMFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/%@Activity.m", identifier]];
        
        if (![fm moveItemAtPath:activityMFileName toPath:resultActivityMFileName error:&error]) {
            return NO;
        }
        
        [self setName:identifier inFile:resultActivityMFileName search:substitutableProjectIdentifier];
        
        NSString* activityHFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/%@Activity.h", substitutableProjectIdentifier]];
        NSString* resultActivityHFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/%@Activity.h", identifier]];
        
        if (![fm moveItemAtPath:activityHFileName toPath:resultActivityHFileName error:&error]) {
            return NO;
        }
        
        [self setName:identifier inFile:resultActivityHFileName search:substitutableProjectIdentifier];
        
        NSString* manifestFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Source/Resources/AndroidManifest.xml"];
        [self setName:identifier inFile:manifestFileName search:substitutableProjectIdentifier];
        [self setName:projName inFile:manifestFileName search:substitutableProjectName];
        
        NSString* androidPlistFileName = [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Source/Resources/Android-Info.plist"];
        [self setName:identifier inFile:androidPlistFileName search:substitutableProjectIdentifier];
        [self setName:projName inFile:androidPlistFileName search:substitutableProjectName];
    }
    
    
    // configure default configuration.json and include opengles2 as a feature
    NSString *apportableConfigFile = [NSString stringWithFormat:@"%@%@", newApprojFileName, @"/configuration.json"];
    NSString *apportableConfigurationContents = [NSString stringWithContentsOfFile:apportableConfigFile encoding:NSUTF8StringEncoding error:&error];
    
    NSString *replacement = [NSString stringWithFormat:@"\"default_target\": {\"project\": \"%@\", \"project_config\": \"Release\", \"target\": \"%@\"},", projName, projName];
    apportableConfigurationContents = [apportableConfigurationContents stringByReplacingOccurrencesOfString:@"default_target" withString:replacement];
    [apportableConfigurationContents writeToFile:apportableConfigFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    return [fm fileExistsAtPath:fileName];
}

- (void) setName:(NSString*)name inFile:(NSString*)fileName search:(NSString*)searchStr
{
    NSMutableData *fileData = [NSMutableData dataWithContentsOfFile:fileName];
    NSData *search = [searchStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *replacement = [name dataUsingEncoding:NSUTF8StringEncoding];
    NSRange found;
    do {
        found = [fileData rangeOfData:search options:0 range:NSMakeRange(0, [fileData length])];
        if (found.location != NSNotFound)
{
            [fileData replaceBytesInRange:found withBytes:[replacement bytes] length:[replacement length]];
	}
    } while (found.location != NSNotFound && found.length > 0);
    [fileData writeToFile:fileName atomically:YES];
}


@end
