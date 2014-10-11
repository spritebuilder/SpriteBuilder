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

-(BOOL) createDefaultProjectAtPath:(NSString*)fileName engine:(CCBTargetEngine)engine programmingLanguage:(CCBProgrammingLanguage)programmingLanguage
{
    NSError *error = nil;
    NSFileManager* fm = [NSFileManager defaultManager];
    
	NSString* substitutableProjectName = @"PROJECTNAME";
    NSString* substitutableProjectIdentifier = @"PROJECTIDENTIFIER";
    NSString* parentPath = [fileName stringByDeletingLastPathComponent];
    
	if (engine == CCBTargetEngineSpriteKit)
	{
		substitutableProjectName = [NSString stringWithFormat:@"SPRITEKIT%@", substitutableProjectName];
	}
	
    NSString* zipFile = [[NSBundle mainBundle] pathForResource:substitutableProjectName ofType:@"zip" inDirectory:@"Generated"];
    
    // Check that zip file exists
    if (![fm fileExistsAtPath:zipFile])
    {
        [[AppDelegate appDelegate] modalDialogTitle:@"Failed to Create Project"
											message:@"The default SpriteBuilder project is missing from this build. Make sure that you build SpriteBuilder using 'Scripts/build_distribution.py --version <versionstr>' the first time you build the program."];
        return NO;
    }
    
    // Unzip resources
    NSTask* zipTask = [[NSTask alloc] init];
    [zipTask setCurrentDirectoryPath:parentPath];
    [zipTask setLaunchPath:@"/usr/bin/unzip"];
    NSArray* args = [NSArray arrayWithObjects:@"-o", zipFile, nil];
    [zipTask setArguments:args];
    [zipTask launch];
    [zipTask waitUntilExit];
    
    // Rename ccbproj
	NSString* ccbproj = [NSString stringWithFormat:@"%@.ccbproj", substitutableProjectName];
    [fm moveItemAtPath:[parentPath stringByAppendingPathComponent:ccbproj] toPath:fileName error:NULL];
    
    // Update the Xcode project
	NSString* xcodeproj = [NSString stringWithFormat:@"%@.xcodeproj", substitutableProjectName];
    NSString* xcodeFileName = [parentPath stringByAppendingPathComponent:xcodeproj];
    NSString* projName = [[fileName lastPathComponent] stringByDeletingPathExtension];
    NSString* identifier = [projName sanitizedIdentifier];
    
    // Update the project
    NSString *pbxprojFile = [xcodeFileName stringByAppendingPathComponent:@"project.pbxproj"];
    [self setName:projName inFile:pbxprojFile search:substitutableProjectName];
    [self setName:identifier inFile:pbxprojFile search:substitutableProjectIdentifier];
    if (programmingLanguage == CCBProgrammingLanguageObjectiveC)
    {
        [self setName:@"IPHONEOS_DEPLOYMENT_TARGET = 5.0"
               inFile:pbxprojFile
               search:@"IPHONEOS_DEPLOYMENT_TARGET = 7.0"];
        [self removeLinesMatching:@".*MainScene[.]swift.*" inFile:pbxprojFile];
    }
    else if (programmingLanguage == CCBProgrammingLanguageSwift)
    {
        [self removeLinesMatching:@".*MainScene[.][hm].*" inFile:pbxprojFile];
    }

    // Update workspace data
    [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:@"project.xcworkspace/contents.xcworkspacedata"] search:substitutableProjectName];
    
    NSArray *platforms = @[@"iOS", @"Android", @"Mac"];
    
    for (id platform in platforms) {
        // Update scheme
        NSString* templateScheme = [NSString stringWithFormat:@"xcshareddata/xcschemes/%@ %@.xcscheme", substitutableProjectName, platform];
        [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:templateScheme] search:substitutableProjectName];

        // Rename scheme file
        NSString* schemeFile = [xcodeFileName stringByAppendingPathComponent:templateScheme];
        NSString* format = [@"iOS" isEqualToString:platform] ? @"%@" : @"%@ %@";  // we want iOS on top

        NSString* newSchemeFile = [[[schemeFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:format, projName, platform]]
            stringByAppendingPathExtension:@"xcscheme"];
        
        if (![fm moveItemAtPath:schemeFile toPath:newSchemeFile error:&error])
        {
            return NO;
        }

        if (![@"iOS" isEqualToString:platform] && programmingLanguage == CCBProgrammingLanguageSwift)
        {
            // Hide scheme for non-iOS Swift projects for now
            if (![fm removeItemAtPath:newSchemeFile error:&error])
            {
                return NO;
            }
        }

        // Update plist
        NSString* plistFileName = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/Resources/Platforms/%@/Info.plist", platform]];
        [self setName:identifier inFile:plistFileName search:substitutableProjectIdentifier];
        [self setName:projName inFile:plistFileName search:substitutableProjectName];
    }

    // Rename Xcode project file
    NSString* newXcodeFileName = [[[xcodeFileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"xcodeproj"];
    
    [fm moveItemAtPath:xcodeFileName toPath:newXcodeFileName error:NULL];
    
    // Update Mac Xib file
    NSString* xibFileName = [parentPath stringByAppendingPathComponent:@"Source/Resources/Platforms/Mac/MainMenu.xib"];
    [self setName:identifier inFile:xibFileName search:substitutableProjectIdentifier];
    [self setName:projName inFile:xibFileName search:substitutableProjectName];

    // Rename Approj project file (apportable)
    NSString* approjFileName = [parentPath stringByAppendingPathComponent:@"PROJECTNAME.approj"];
    projName = [[fileName lastPathComponent] stringByDeletingPathExtension];

    NSString* newApprojFileName = [[[approjFileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"approj"];
    [fm moveItemAtPath:approjFileName toPath:newApprojFileName error:NULL];

    // Android
    NSString* activityJavaFileName = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/Platforms/Android/java/org/cocos2d/%@/%@Activity.java", substitutableProjectIdentifier, substitutableProjectIdentifier]];
    if ([fm fileExistsAtPath:activityJavaFileName])
    {
        NSString* resultActivityJavaFileName = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/Platforms/Android/java/org/cocos2d/%@/%@Activity.java", identifier, identifier]];
        
        if (![fm createDirectoryAtPath:[resultActivityJavaFileName stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]) {
            return NO;
        }
        
        if (![fm moveItemAtPath:activityJavaFileName toPath:resultActivityJavaFileName error:&error]) {
            return NO;
        }
        [self setName:identifier inFile:resultActivityJavaFileName search:substitutableProjectIdentifier];
        
        NSString* activityMFileName = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/Platforms/Android/%@Activity.m", substitutableProjectIdentifier]];
        NSString* resultActivityMFileName = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/Platforms/Android/%@Activity.m", identifier]];
        
        if (![fm moveItemAtPath:activityMFileName toPath:resultActivityMFileName error:&error]) {
            return NO;
        }
        
        [self setName:identifier inFile:resultActivityMFileName search:substitutableProjectIdentifier];
        
        NSString* activityHFileName = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/Platforms/Android/%@Activity.h", substitutableProjectIdentifier]];
        NSString* resultActivityHFileName = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/Platforms/Android/%@Activity.h", identifier]];
        
        if (![fm moveItemAtPath:activityHFileName toPath:resultActivityHFileName error:&error]) {
            return NO;
        }
        
        [self setName:identifier inFile:resultActivityHFileName search:substitutableProjectIdentifier];
        
        NSString* manifestFileName = [parentPath stringByAppendingPathComponent:@"Source/Resources/Platforms/Android/AndroidManifest.xml"];
        [self setName:identifier inFile:manifestFileName search:substitutableProjectIdentifier];
        [self setName:projName inFile:manifestFileName search:substitutableProjectName];
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

- (void) removeLinesMatching:(NSString*)pattern inFile:(NSString*)fileName
{
    NSData *fileData = [NSData dataWithContentsOfFile:fileName];
    NSString *fileString = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *updatedString = [regex stringByReplacingMatchesInString:fileString
                                                         options:0
                                                           range:NSMakeRange(0, [fileString length])
                                                    withTemplate:@""];
    NSData *updatedFileData = [updatedString dataUsingEncoding:NSUTF8StringEncoding];
    [updatedFileData writeToFile:fileName atomically:YES];
}

@end
