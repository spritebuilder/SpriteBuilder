//
//  MigrationLogWindowController.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 23.02.15.
//
//

#import "MigrationLogWindowController.h"
#import "NSAlert+Convenience.h"

@interface MigrationLogWindowController ()

@property (nonatomic, strong) NSArray *logEntries;
@property (nonatomic, strong) NSDate *timeStamp;

@end


@implementation MigrationLogWindowController

- (instancetype)initWithLogEntries:(NSArray *)logEntries
{
    self = [super initWithWindowNibName:@"MigrationLogWindowController" owner:self];

    if (self)
    {
        self.logEntries = logEntries;
        self.timeStamp = [NSDate date];
    }

    return self;
}

- (IBAction)saveToFile:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.canCreateDirectories = YES;
    savePanel.canHide = NO;
    savePanel.treatsFilePackagesAsDirectories = YES;
    savePanel.nameFieldLabel = @"Log file";
    savePanel.delegate = self;
    savePanel.nameFieldStringValue = [self suggestedFilename];
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
    {
        if (result == NSFileHandlingPanelCancelButton)
        {
            return;
        }

        NSError *error;
        if (![[self log] writeToFile:savePanel.URL.path atomically:YES encoding:NSUTF8StringEncoding error:&error])
        {
            [NSAlert showModalDialogWithTitle:@"Error" message:[NSString stringWithFormat:@"Log file could not be written: %@", error]];
        }
    }];
}

- (NSString *)suggestedFilename
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss";
    NSString *projectNameVal = @"";
    if (_projectName)
    {
        projectNameVal = [NSString stringWithFormat:@"-%@", _projectName];
    }
    
    return [NSString stringWithFormat:@"MigrationFailed%@-%@.log", projectNameVal, [dateFormatter stringFromDate:_timeStamp]];
}

- (IBAction)copyToClipboard:(id)sender
{
    NSString *log = [self log];
    if (!log)
    {
        return;
    }

    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:log  forType:NSStringPboardType];
}

- (IBAction)closeLog:(id)sender
{
    [self.window performClose:self];
    [NSApp stopModal];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.window.title = [self suggestedFilename];

    NSScrollView *scrollView = [_logTextView enclosingScrollView];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

    NSTextContainer *textContainer = [_logTextView textContainer];
    [textContainer setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [textContainer setWidthTracksTextView:NO];
    [textContainer setHeightTracksTextView:NO];

    _logTextView.font = [NSFont fontWithName:@"Courier" size:11.0];
    [_logTextView setHorizontallyResizable:YES];

    _logTextView.string = [self log];

    [_logTextView setNeedsDisplay:YES];
    [_logTextView setNeedsLayout:YES];
}

- (NSString *)log
{
    return [_logEntries componentsJoinedByString:@"\n"];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp stopModal];
}

@end
