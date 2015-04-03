//
//  MigrationDialogWindowController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 24.02.15.
//
//

#import "MigrationDialogWindowController.h"
#import "MigrationController.h"
#import "CCFileLocator.h"
#import "MigrationLogger.h"
#import "NSAlert+Convenience.h"

@interface MigrationDialogWindowController ()

@property (nonatomic, copy) NSString *logFilepath;
@property (nonatomic, strong) MigrationController *migrationController;
@property (nonatomic) BOOL migrated;
@property (nonatomic) BOOL migrationResult;
@property (nonatomic, strong) MigrationLogger *migrationLogger;

@end


@implementation MigrationDialogWindowController

- (instancetype)initWithMigrationController:(MigrationController *)migrationController
{
    self = [super initWithWindowNibName:@"MigrationDialogWindowController"];

    if (self)
    {
        self.migrationController = migrationController;
        self.migrationResult = NO;

        self.migrationLogger = [[MigrationLogger alloc] initWithLogToConsole:NO];

        _migrationController = migrationController;
        _migrationController.logger = _migrationLogger ;
    }

    return self;
}

- (SBMigrationDialogResult)dialogResult
{
    return _migrationResult
        ? SBMigrationDialogResultMigrateSuccessful
        : SBMigrationDialogResultMigrateFailed;
}

- (void)setMigrated:(BOOL)migrated
{
    _migrated = migrated;

    if (_migrated)
    {
        [_buttonOne setTitle:@"Show Log"];
        [_buttonOne setAction:@selector(showLog)];

        [_buttonTwo setTitle:@"Close"];
        [_buttonTwo setAction:@selector(close)];
    }
    else
    {
        [_buttonOne setTitle:@"Cancel"];
        [_buttonOne setAction:@selector(close)];

        [_buttonTwo setTitle:@"Migrate"];
        [_buttonTwo setAction:@selector(migrate)];
    }
}

- (void)migrate
{
    if (_migrated)
    {
        return;
    }

    NSError *error;
    if (_logHeadline)
    {
        [_migrationLogger log:_logHeadline];
    }

    if (![_migrationController migrateWithError:&error])
    {
        [self setText:[NSString stringWithFormat:
            @"<h3 style='color: red'>Migration failed with the following error: %@.</h3><br/> "
            "Please ask for help on the <a href='http://forum.spritebuilder.com/'>Spritebuilder forum</a> or <a href='https://github.com/spritebuilder/SpriteBuilder/issues/new'>create an issue on github.</a>"
            "Please provide the log file for a bug report.", error]];
        self.migrationResult = NO;
        [_migrationLogger log:@"Migration failed."];
    }
    else
    {
        [self setText:[NSString stringWithFormat:@"<h3 style='color: green'>Migration was successful!</h3>"]];
        self.migrationResult = YES;
        [_migrationLogger log:@"Migration successful!"];
    }

    [self saveLogToFile];

    self.migrated = YES;
}

- (void)close
{
    [self.window performClose:self];
    [NSApp stopModalWithCode:[self dialogResult]];
}

- (void)showLog
{
    [[NSWorkspace sharedWorkspace] selectFile:_logFilepath inFileViewerRootedAtPath:@""];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.window.title = _title
        ? _title
        : @"Migration";

    // sets implicitly the button actions and titles
    self.migrated = NO;

    [self setStartMigrationInfoText];

    [_textView setTextContainerInset:NSMakeSize(5.0, 10.0)];
    [_textView setEditable:NO];
    [_textView setSelectable:YES];
    [_textView setDrawsBackground:NO];
}

- (void)setStartMigrationInfoText
{
    NSString *intro =
            @"<h3>The Project/Document is of an older version, migration is required.</h3><br/>"
            "<b style='color: red'>We strongly recommend to make a backup of your files before you proceed."
            "It is even better to use a version control system such as <a href='http://git-scm.com/'>GIT</a> to keep track of changes to your files.</b><br/><br/>"
            "If an error occurs the changes will be rolled back but the project/document can't be opened. A log file will be created for details.";

    [self setText:intro];
}

- (void)setText:(id)text
{
    NSString *htmlMessage =
            [NSString stringWithFormat:
                    @"<html><head><style>* {font-family: \"Helvetica Neue\", sans-serif; padding:0; margin:0;}</style></head><body>"
                     "%@"
                     "</body></html>", text];

    NSDictionary *textAttributes;
    NSAttributedString *formattedString = [[NSAttributedString alloc] initWithHTML:[htmlMessage dataUsingEncoding:NSUTF8StringEncoding]
                                                                documentAttributes:&textAttributes];

    [[_textView textStorage] setAttributedString:formattedString];
}

- (NSInteger)startMigration
{
    [self.window center];

    return [_migrationController isMigrationRequired]
       ? [NSApp runModalForWindow:self.window]
       : 1;
}

- (void)saveLogToFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *path = paths[0];
    if (path)
    {
        NSString *fullPathLogsDir = [path stringByAppendingPathComponent:@"SpriteBuilder/Logs"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:fullPathLogsDir])
        {
            [fileManager createDirectoryAtPath:fullPathLogsDir withIntermediateDirectories:YES attributes:nil error:nil];
        }

        self.logFilepath = [fullPathLogsDir stringByAppendingPathComponent:[self suggestedFilenameWithProjectName:_logItemName]];

        NSError *error;
        if (![[_migrationLogger log] writeToFile:_logFilepath atomically:YES encoding:NSUTF8StringEncoding error:&error])
        {
            [NSAlert showModalDialogWithTitle:@"Error" message:[NSString stringWithFormat:@"Log file could not be written: %@", error]];
        }
    }
}

- (NSString *)suggestedFilenameWithProjectName:(NSString *)projectName
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss";

    return [NSString stringWithFormat:@"Migration-%@-%@.log", projectName, [dateFormatter stringFromDate:[NSDate date]]];
}


#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp stopModalWithCode:[self dialogResult]];
}

@end
