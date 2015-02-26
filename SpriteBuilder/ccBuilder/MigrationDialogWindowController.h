//
//  MigrationDialogWindowController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 24.02.15.
//
//

#import <Cocoa/Cocoa.h>

@class MigrationController;

typedef enum
{
    SBMigrationDialogResultMigrateFailed = 0,
    SBMigrationDialogResultMigrateSuccessful,

} SBMigrationDialogResult;

@interface MigrationDialogWindowController : NSWindowController <NSOpenSavePanelDelegate, NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSButton *buttonOne;
@property (nonatomic, strong) IBOutlet NSButton *buttonTwo;
@property (nonatomic, strong) IBOutlet NSTextView *textView;

// Title of the migration dialog window
@property (nonatomic, copy) NSString *title;
// The name of the document or project, no full path, used for generating the log file name
@property (nonatomic, copy) NSString *logItemName;
// First line of the log as soon as the migration starts, omitted in log if nil
@property (nonatomic, copy) NSString *logHeadline;

- (instancetype)initWithMigrationController:(MigrationController *)migrationController;

- (NSInteger)startMigration;

@end
