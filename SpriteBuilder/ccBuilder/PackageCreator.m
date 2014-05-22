#import "PackageCreator.h"
#import "NewPackageWindowController.h"
#import "ProjectSettings.h"
#import "SnapLayerKeys.h"


@interface PackageCreator ()

@property (nonatomic, weak) NSWindow *window;

@end


@implementation PackageCreator

- (instancetype)init
{
    NSLog(@"ERROR: Use initWithWindow: to create instances");
    [self doesNotRecognizeSelector:_cmd];
}

- (instancetype)initWithWindow:(NSWindow *)window
{
    self = [super init];

    if (self)
    {
        self.window = window;
    }

    return self;
}

- (void)showCreateNewPackageDialog
{
    NewPackageWindowController *packageWindowController = [[NewPackageWindowController alloc] init];
    packageWindowController.delegate = self;

    // Show new document sheet
    [NSApp beginSheet:[packageWindowController window]
       modalForWindow:_window
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];

    NSInteger acceptedModal = [NSApp runModalForWindow:[packageWindowController window]];
    [NSApp endSheet:[packageWindowController window]];
    [[packageWindowController window] close];

    if (acceptedModal == 1)
    {
        NSError *error;
        if (![self createPackageWithName:packageWindowController.packageName error:&error])
        {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error"
                                             defaultButton:@"Ok"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:error.localizedDescription];

            [alert runModal];
        }
    }
}


- (BOOL)createPackageWithName:(NSString *)packageName error:(NSError **)error
{
    NSLog(@"[PACKAGE] Creating package %@", packageName);

    NSString *newPackagePath = [_projectSettings.projectPathDir stringByAppendingPathComponent:packageName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager createDirectoryAtPath:newPackagePath withIntermediateDirectories:NO attributes:nil error:error])
    {
        if ([_projectSettings addResourcePath:newPackagePath error:error])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:RESOURCE_PATHS_CHANGED
                                                                object:nil];
            return YES;
        }
    }
    return NO;
}

# pragma mark - PackageCreateDelegate

- (BOOL)canCreatePackageWithName:(NSString *)packageName error:(NSError **)error
{
/*
    *error = [NSError errorWithDomain:SBErrorDomain
                                 code:create constant
                             userInfo:@{NSLocalizedDescriptionKey:@"Package already exists"}];
*/

    return YES;
}

@end