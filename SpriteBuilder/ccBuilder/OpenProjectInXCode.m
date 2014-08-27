#import "OpenProjectInXCode.h"


@implementation OpenProjectInXCode

- (void)openProject:(NSString *)projectPath
{
    NSAssert(projectPath != nil, @"projectPath should be set");

    NSString *templateScriptPath = [[NSBundle mainBundle] pathForResource:@"openXcodeProject" ofType:@"AppleScript"];
    NSString *templateScript = [NSString stringWithContentsOfFile:templateScriptPath encoding:NSUTF8StringEncoding error:nil];
    templateScript = [templateScript stringByReplacingOccurrencesOfString:@"ABSOLUTE_PATH_TO_PROJECT" withString:projectPath];

    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:templateScript];
    NSDictionary *errors;
    if (![appleScript executeAndReturnError:&errors])
    {
        NSLog(@"ERRORS: %@", errors);
    }
}

@end