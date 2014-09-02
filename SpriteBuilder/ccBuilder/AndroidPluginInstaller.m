//
//  AndroidPluginInstaller.m
//  SpriteBuilder
//
//  Created by John Twigg on 6/27/14.
//
//

#import "AndroidPluginInstaller.h"



#ifdef DEBUG
//#define SBPRO_TEST_INSTALLER
#endif

static const float kSBProPluginVersion = 4.01;


NSString*   kSBDefualtsVersionIdentifier = @"SBProPluginVersion";
NSString*   kSBDefualtsMD5Identifier = @"SBProPluginMD5";


@implementation AndroidPluginInstaller

+(NSString*)xcodePluginPath
{
	
	
	NSString *pluginBundlePath = [[NSBundle mainBundle] pathForResource:@"AndroidXcodePlugin" ofType:@"zip" inDirectory:@"Generated"];
	NSFileManager * fm =[[NSFileManager alloc] init];
	if(![fm fileExistsAtPath:pluginBundlePath])
	{
		return nil;
	}
	return pluginBundlePath;
}

+(BOOL)runPythonScript:(NSString*)command output:(NSString**)result
{
	
	
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/python";
	
	NSString * pluginBundlePath = [self xcodePluginPath];
	if(!pluginBundlePath)
	{
		*result = [NSString stringWithFormat:@"AndroidXcodePlugin is not in Generated Folder. Android Xcode plugin will not be installed properly."];
		return false;
	}

	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"plugin_installer" ofType:@"py"];
    task.arguments = [NSArray arrayWithObjects: scriptPath, command, pluginBundlePath, nil];
	
    // NSLog breaks if we don't do this...
    [task setStandardInput: [NSPipe pipe]];
	
    NSPipe *stdOutPipe = nil;
    stdOutPipe = [NSPipe pipe];
    [task setStandardOutput:stdOutPipe];	
	
    NSPipe* stdErrPipe = nil;
    stdErrPipe = [NSPipe pipe];
    [task setStandardError: stdErrPipe];
	
    [task launch];
	
    NSData* data = [[stdOutPipe fileHandleForReading] readDataToEndOfFile];
	
    [task waitUntilExit];
	
    NSInteger exitCode = task.terminationStatus;
	*result = [[NSString alloc] initWithBytes: data.bytes length:data.length encoding: NSUTF8StringEncoding];
	
	if( exitCode != 0)
	{
		NSLog(@"Error with python: %@ %@", task.launchPath, command);
		NSLog(@"%@",*result);
	}
	
    return exitCode == 0;
}

+(BOOL)installPlugin:(NSString**)output
{
	return [self runPythonScript:@"install" output:output];
}

+(BOOL)removePlugin:(NSString**)output
{
	return [self runPythonScript:@"clean" output:output];
}

+(BOOL)verifyPluginInstallation:(NSString**)output
{
	return [self runPythonScript:@"validate" output:output];
}

+(NSString*)getPluginMD5
{
	
	NSString * pluginBundlePath = [self xcodePluginPath];
	if(pluginBundlePath == nil)
		return nil;
	
	NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/sbin/md5";
	task.arguments = [NSArray arrayWithObjects: @"-q", pluginBundlePath, nil];

	
	// NSLog breaks if we don't do this...
    [task setStandardInput: [NSPipe pipe]];
	
    NSPipe *stdOutPipe = nil;
    stdOutPipe = [NSPipe pipe];
    [task setStandardOutput:stdOutPipe];
	
    NSPipe* stdErrPipe = nil;
    stdErrPipe = [NSPipe pipe];
    [task setStandardError: stdErrPipe];
	
    [task launch];
	
    NSData* data = [[stdOutPipe fileHandleForReading] readDataToEndOfFile];
	
    [task waitUntilExit];
	
   // NSInteger exitCode = task.terminationStatus;

	NSString * md5 =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return [md5 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	
}

NSString * getVersionFile()
{
	NSArray *domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES);
	NSString *baseDir= [domains objectAtIndex:0];
	NSString *versionFilePath = [baseDir stringByAppendingPathComponent:@"Application Support/Developer/Shared/Xcode/Plug-ins/AndroidPluginFile.plist"];
	return versionFilePath;
}



+(BOOL)needsInstallation
{
#ifdef SBPRO_TEST_INSTALLER
	return YES;
#endif
	
	NSFileManager * fm =[[NSFileManager alloc] init];
	
	NSString *versionFilePath = getVersionFile();
	
	if(![fm fileExistsAtPath:versionFilePath])
		return YES;
	
	NSDictionary * versionInfo = [NSDictionary dictionaryWithContentsOfFile:versionFilePath];
	if(versionInfo == nil)
		return YES;
		
	NSNumber * currentVersion = versionInfo[kSBDefualtsVersionIdentifier];
	if(currentVersion == nil || [currentVersion floatValue] < kSBProPluginVersion)
	{
		return YES;
	}
	
	NSString* currentInstalledMD5 = versionInfo[kSBDefualtsMD5Identifier];
	if(currentInstalledMD5 == nil)
		return YES;
	
	NSString * shippedPluginMD5 = [self getPluginMD5];
	if(shippedPluginMD5 == nil)
	{
		return YES;
	}
	
	if(![currentInstalledMD5 isEqualToString:shippedPluginMD5])
	{
		return YES;
	}
	
	return NO;
}

+(void)setInstallationVersion
{
	NSString *versionFilePath = getVersionFile();
	NSString * shippedPluginMD5 = [self getPluginMD5];
	
	NSDictionary * versionInfo = @{kSBDefualtsVersionIdentifier : @(kSBProPluginVersion),kSBDefualtsMD5Identifier : shippedPluginMD5 };
	[versionInfo writeToFile:versionFilePath atomically:YES];
}


@end
