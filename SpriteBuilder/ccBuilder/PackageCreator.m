#import "PackageCreator.h"
#import "NewPackageWindowController.h"


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
        NSLog(@"[PACKAGE] Creating package %@", packageWindowController.packageName);
    }
}

# pragma mark - PackageCreateDelegate

- (BOOL)canCreatePackageWithName:(NSString *)packageName error:(NSError **)error
{
    *error = [NSError errorWithDomain:@"asdasd" code:100 userInfo:@{NSLocalizedDescriptionKey:@"Package already exists"}];
    return NO;
}

@end