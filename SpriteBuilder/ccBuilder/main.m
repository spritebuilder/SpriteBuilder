//
//  Copyright 2011 Viktor Lidholt. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PlugInManager.h"
#import "PlugInExport.h"
#import "ProjectSettings.h"
#import "CCBPublisher.h"
#import "CCBWarnings.h"
#import "ResourceManager.h"
#import "TaskStatusUpdaterProtocol.h"


@interface ConsoleTaskStatusUpdater : NSObject <TaskStatusUpdaterProtocol>
- (void)updateStatusText:(NSString *)text;
- (void)setProgress:(double)progress;
@end

@implementation ConsoleTaskStatusUpdater
- (void)updateStatusText:(NSString *)text
{
    fprintf(stdout, "%s\n", [text UTF8String]);
}
- (void)setProgress:(double)progress
{
    
}
@end

@interface FakeTaskStatusUpdater : NSObject <TaskStatusUpdaterProtocol>
- (void)updateStatusText:(NSString *)text;
- (void)setProgress:(double)progress;
@end

@implementation FakeTaskStatusUpdater
- (void)updateStatusText:(NSString *)text { }
- (void)setProgress:(double)progress { }
@end


static void	parseArgs(NSArray *args, NSString **configuration, NSString **inputPath, BOOL *verbose)
{
	*configuration = @"Default";
    *inputPath = nil;
	
	NSString			*prog = [args objectAtIndex:0];
	BOOL				stillParsingArgs = YES;
	
	for (NSInteger i = 1; i < args.count; ++i)
	{
		NSString		*arg = [args objectAtIndex:i];
		
		if (stillParsingArgs && ([arg isEqualToString:@"-h"] || [arg isEqualToString:@"--help"]))
		{
			fprintf(stdout, "%s", [[NSString stringWithFormat:
                                    @"Usage:\n"
                                    @"%@ [-c <Debug/Release>|--configuration=<Debug/Release>] [-v|--verbose] [-p <inputdir>|--publish=<inputdir>]\n"
                                    @"%@ -h|--help\n"
                                    @"%@ --version\n", prog, prog, prog] UTF8String]);
			exit(EXIT_SUCCESS);
		}
		else if (stillParsingArgs && [arg isEqualToString:@"--version"])
		{
			fprintf(stdout, "%s", [[NSString stringWithFormat:
                                    @"%@\n"
                                    @"Version %@\n", prog, [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]] UTF8String]); // do not hardcode me
			exit(EXIT_SUCCESS);
		}
		
		else if (stillParsingArgs && ([arg isEqualToString:@"-v"] || [arg isEqualToString:@"--verbose"]))
			*verbose = YES;
        
		else if (stillParsingArgs && [arg isEqualToString:@"-c"])
			*configuration = [args objectAtIndex:++i];
		else if (stillParsingArgs && [arg hasPrefix:@"-c"])
			*configuration = [arg substringFromIndex:2];
		else if (stillParsingArgs && [arg hasPrefix:@"--configuration="])
			*configuration = [arg substringFromIndex:16];
        
        else if (stillParsingArgs && [arg isEqualToString:@"-p"])
			*inputPath = [args objectAtIndex:++i];
		else if (stillParsingArgs && [arg hasPrefix:@"-p"])
			*inputPath = [arg substringFromIndex:2];
		else if (stillParsingArgs && [arg hasPrefix:@"--publish="])
			*inputPath = [arg substringFromIndex:10];
        
		else if (stillParsingArgs && [arg isEqualToString:@"--"])
			stillParsingArgs = NO;
		else
		{
			stillParsingArgs = NO;
		}
	}
}

int main(int argc, char *argv[])
{
    
@autoreleasepool
    {
        NSMutableArray			*args = [NSMutableArray array];
        
        // It is trivially possible to get the OS to pass non-UTF-8 arguments,
        //	but there is no immediate solution. For now, don't try to use this
        //	with a non-Unicode terminal.
        for (int i = 0; i < argc; ++i)
            [args addObject:[NSString stringWithUTF8String:argv[i]]];
        
        NSString				*configuration = nil;
        NSString				*inputPath = nil;
        BOOL					verbose = NO;
        
        BOOL succces = NO;
        
        [[PlugInManager sharedManager] loadPlugIns];
        parseArgs(args, &configuration, &inputPath, &verbose);
        
        NSString *fileName = inputPath;
        
        if(fileName)
        {
            
            NSString* projName = [[fileName lastPathComponent] stringByDeletingPathExtension];
            fileName = [[fileName stringByAppendingPathComponent:projName] stringByAppendingPathExtension:@"ccbproj"];
            
            // Load the project file
            NSMutableDictionary* projectDict = [NSMutableDictionary dictionaryWithContentsOfFile:fileName];
            if (!projectDict)
            {
                fprintf(stdout, "%s", "Failed to open the project. File may be missing or invalid.");
                return EXIT_FAILURE;
            }
            
            ProjectSettings* project = [[ProjectSettings alloc] initWithSerialization:projectDict];
            if (!project)
            {
                fprintf(stdout, "%s", "Failed to open the project. File is invalid or is created with a newer version of SpriteBuilder");
                return EXIT_FAILURE;
            }
            project.projectPath = fileName;
            
            if(configuration)
            {
                if([configuration isEqualToString:@"Release"])
                    project.publishEnvironment = PublishEnvironmentRelease;
                if([configuration isEqualToString:@"Debug"])
                    project.publishEnvironment = PublishEnvironmentDevelop;
            }
            
            CCBWarnings* warnings = [[CCBWarnings alloc] init];
            warnings.warningsDescription = @"Publisher Warnings";
            
            [ResourceManager sharedManager].projectSettings = project;
            
            [[ResourceManager sharedManager] removeAllDirectories];
            
            // Setup links to directories
            for (NSString* dir in [project absoluteResourcePaths])
            {
                [[ResourceManager sharedManager] addDirectory:dir];
            }
            [[ResourceManager sharedManager] setActiveDirectories:[project absoluteResourcePaths]];
            
            CCBPublisher* publisher = [[CCBPublisher alloc] initWithProjectSettings:project warnings:warnings];
            
            if(verbose)
                publisher.taskStatusUpdater = [[ConsoleTaskStatusUpdater alloc] init];
            else
                publisher.taskStatusUpdater = [[FakeTaskStatusUpdater alloc] init];
            
            succces = [publisher start];
            
            for (CCBWarning *warning in warnings.warnings)
            {
                fprintf(stdout, "warning:%s in file:%s\n", [warning.message UTF8String], [warning.relatedFile UTF8String]);
            }
            
            exit(succces ? EXIT_SUCCESS : EXIT_FAILURE);
        }
    }


    return NSApplicationMain(argc, (const char **)argv);
}
