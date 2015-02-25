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

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *logItemName;

- (instancetype)initWithMigrationController:(MigrationController *)migrationController;

- (NSInteger)startMigration;

@end
