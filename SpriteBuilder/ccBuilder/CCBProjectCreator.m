//
//  CCBProjectCreator.m
//  SpriteBuilder
//
//  Created by Viktor on 10/11/13.
//
//

#import <Foundation/Foundation.h>
#import "CCBProjectCreator.h"
#import "AppDelegate.h"
#import "CCBFileUtil.h"

@implementation NSString (IdentifierSanitizer)

- (NSString *)sanitizedIdentifier
{
    NSString *identifier = [self stringByTrimmingCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
    NSMutableString *sanitized = [NSMutableString new];

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

static NSString *substitutableProjectName = @"PROJECTNAME";
static NSString *substitutableProjectIdentifier = @"PROJECTIDENTIFIER";

@implementation CCBProjectCreator

- (BOOL)createDefaultProjectAtPath:(NSString *)fileName engine:(CCBTargetEngine)engine programmingLanguage:(CCBProgrammingLanguage)programmingLanguage
{
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *parentPath = [fileName stringByDeletingLastPathComponent];

    NSString *zipFile = [[NSBundle mainBundle] pathForResource:substitutableProjectName ofType:@"zip" inDirectory:@"Generated"];

    // Check that zip file exists
    if (![fm fileExistsAtPath:zipFile])
    {
        [[AppDelegate appDelegate] modalDialogTitle:@"Failed to Create Project"
                                            message:@"The default SpriteBuilder project is missing from this build. Make sure that you build SpriteBuilder using 'Scripts/build_distribution.py --version <versionstr>' the first time you build the program."];
        return NO;
    }

    // Unzip resources
    NSTask *zipTask = [[NSTask alloc] init];
    [zipTask setCurrentDirectoryPath:parentPath];
    [zipTask setLaunchPath:@"/usr/bin/unzip"];
    NSArray *args = @[@"-o", zipFile];
    [zipTask setArguments:args];
    [zipTask launch];
    [zipTask waitUntilExit];

    // Rename ccbproj
    NSString *ccbproj = [NSString stringWithFormat:@"%@.ccbproj", substitutableProjectName];
    [fm moveItemAtPath:[parentPath stringByAppendingPathComponent:ccbproj] toPath:fileName error:NULL];

    // Update the Xcode project
    NSString *xcodeproj = [NSString stringWithFormat:@"%@.xcodeproj", substitutableProjectName];
    NSString *xcodeFileName = [parentPath stringByAppendingPathComponent:xcodeproj];
    NSString *projName = [[fileName lastPathComponent] stringByDeletingPathExtension];
    NSString *identifier = [projName sanitizedIdentifier];

    NSDictionary *renameParams = @{substitutableProjectIdentifier:identifier, substitutableProjectName:projName};

    // Update the project
    NSString *pbxprojFile = [xcodeFileName stringByAppendingPathComponent:@"project.pbxproj"];
    [self setName:projName inFile:pbxprojFile search:substitutableProjectName];
    [self setName:identifier inFile:pbxprojFile search:substitutableProjectIdentifier];

    NSArray *filesToRemove;
    if (programmingLanguage == CCBProgrammingLanguageObjectiveC)
    {
        [self setName:@"IPHONEOS_DEPLOYMENT_TARGET = 6.0"
               inFile:pbxprojFile
               search:@"IPHONEOS_DEPLOYMENT_TARGET = 7.0"];
        [self setName:@"MACOSX_DEPLOYMENT_TARGET = 10.9"
               inFile:pbxprojFile
               search:@"MACOSX_DEPLOYMENT_TARGET = 10.10"];
        [self removeLinesMatching:@".*MainScene[.]swift.*" inFile:pbxprojFile];
        filesToRemove = @[@"Source/MainScene.swift"];
    }
    else if (programmingLanguage == CCBProgrammingLanguageSwift)
    {
        [self removeLinesMatching:@".*MainScene[.][hm].*" inFile:pbxprojFile];
        filesToRemove = @[@"Source/MainScene.h", @"Source/MainScene.m"];
    }

    for (NSString *file in filesToRemove)
    {
        if (![fm removeItemAtPath:[parentPath stringByAppendingPathComponent:file] error:&error])
        {
            return NO;
        }
    }

    // Update workspace data
    [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:@"project.xcworkspace/contents.xcworkspacedata"] search:substitutableProjectName];

    NSArray *platforms = @[@"iOS", @"Android", @"Mac"];

    for (id platform in platforms)
    {
        // Update scheme
        NSString *templateScheme = [NSString stringWithFormat:@"xcshareddata/xcschemes/%@ %@.xcscheme", substitutableProjectName, platform];
        [self setName:projName inFile:[xcodeFileName stringByAppendingPathComponent:templateScheme] search:substitutableProjectName];

        // Rename scheme file
        NSString *schemeFile = [xcodeFileName stringByAppendingPathComponent:templateScheme];
        NSString *format = [@"iOS" isEqualToString:platform] ? @"%@" : @"%@ %@";  // we want iOS on top

        NSString *newSchemeFile = [[[schemeFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:format, projName, platform]]
                stringByAppendingPathExtension:@"xcscheme"];

        if (![fm moveItemAtPath:schemeFile toPath:newSchemeFile error:&error])
        {
            return NO;
        }

        // Update plist
        NSString *plistFileName = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/Resources/Platforms/%@/Info.plist", platform]];
        [self replace:renameParams in:plistFileName];
    }

    // Rename Xcode project file
    NSString *newXcodeFileName = [[[xcodeFileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"xcodeproj"];

    [fm moveItemAtPath:xcodeFileName toPath:newXcodeFileName error:NULL];

    //Interpolate new project values into all remaining files with placeholders

    NSString *xibFileName = [parentPath stringByAppendingPathComponent:@"Source/Resources/Platforms/Mac/MainMenu.xib"];
    NSString *macAppDelegateMFileName = [parentPath stringByAppendingPathComponent:@"Source/Platforms/Mac/AppDelegate.m"];
    NSString *iosAppDelegateMFileName = [parentPath stringByAppendingPathComponent:@"Source/Platforms/iOS/AppDelegate.m"];
    NSString *controllerHName = [parentPath stringByAppendingPathComponent:@"Source/PROJECTIDENTIFIERController.h"];
    NSString *controllerMName = [parentPath stringByAppendingPathComponent:@"Source/PROJECTIDENTIFIERController.m"];

    NSMutableArray *filesNeedingInterpolation = [NSMutableArray arrayWithArray: @[xibFileName, macAppDelegateMFileName,
            iosAppDelegateMFileName, controllerHName,controllerMName]];

    //Add android files if they exist
    NSString *activityMFileName = [parentPath stringByAppendingPathComponent:
            [NSString stringWithFormat:@"Source/Platforms/Android/%@Activity.m", substitutableProjectIdentifier]];
    if ([fm fileExistsAtPath:activityMFileName])
    {
        NSString *activityHFileName = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Source/Platforms/Android/%@Activity.h", substitutableProjectIdentifier]];
        NSString *manifestFileName = [parentPath stringByAppendingPathComponent:@"Source/Resources/Platforms/Android/AndroidManifest.xml"];

        [filesNeedingInterpolation addObjectsFromArray: @[activityMFileName,activityHFileName, manifestFileName]];
    }

    //Perform the interpolation
    for (NSString* filePath in filesNeedingInterpolation)
    {
        [self replace:renameParams in:filePath];
    }

    // perform cleanup to remove unnecessary files which only bloat the project
    [CCBFileUtil cleanupSpriteBuilderProjectAtPath:fileName];

    return [fm fileExistsAtPath:fileName];
};

- (void)replace:(NSDictionary *)substitutions in:(NSString *)fileName
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *resultFilename = [NSString stringWithString:fileName];

    for( NSString*key in substitutions.allKeys)
    {
        resultFilename = [resultFilename stringByReplacingOccurrencesOfString:key withString:substitutions[key]];
    }

    BOOL renameRequired = ![resultFilename isEqualToString:fileName];
    if(renameRequired)
    {
        NSError *error;
        [fm moveItemAtPath:fileName toPath:resultFilename error:&error];
        NSAssert(!error, @"error occurred renaming %@ - %@", fileName, [error description]);
    }

    for( NSString*key in substitutions.allKeys)
    {
        [self setName:substitutions[key] inFile:resultFilename search:key];
    }
}

- (void)setName:(NSString *)name inFile:(NSString *)fileName search:(NSString *)searchStr
{
    NSMutableData *fileData = [NSMutableData dataWithContentsOfFile:fileName];
    NSData *search = [searchStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *replacement = [name dataUsingEncoding:NSUTF8StringEncoding];
    NSRange found;
    do
    {
        found = [fileData rangeOfData:search options:0 range:NSMakeRange(0, [fileData length])];
        if (found.location != NSNotFound)
        {
            [fileData replaceBytesInRange:found withBytes:[replacement bytes] length:[replacement length]];
        }
    }
    while (found.location != NSNotFound && found.length > 0);
    [fileData writeToFile:fileName atomically:YES];
}

- (void)removeLinesMatching:(NSString *)pattern inFile:(NSString *)fileName
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
