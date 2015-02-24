//
//  MigrationLogWindowController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 23.02.15.
//
//

#import <Cocoa/Cocoa.h>

@interface MigrationLogWindowController : NSWindowController <NSWindowDelegate, NSOpenSavePanelDelegate>

@property (nonatomic, strong) IBOutlet NSTextView *logTextView;
@property (nonatomic, copy) NSString *projectName;

- (IBAction)saveToFile:(id)sender;
- (IBAction)copyToClipboard:(id)sender;
- (IBAction)closeLog:(id)sender;

- (instancetype)initWithLogEntries:(NSArray *)logEntries;

@end
