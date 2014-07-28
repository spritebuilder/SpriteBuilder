//
//  ProjectSettingsWindowController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 24.07.14.
//
//

#import <Cocoa/Cocoa.h>
#import "CCBModalSheetController.h"

@class ProjectSettings;
@class PackagePublishSettings;

@interface ProjectSettingsWindowController : CCBModalSheetController <NSTableViewDelegate>

@property (nonatomic, weak) ProjectSettings* projectSettings;
@property (nonatomic, strong) PackagePublishSettings *currentPackageSettings;
@property (nonatomic, strong) NSMutableArray *settingsList;

@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSView *detailView;

- (IBAction)selectPublishDirectoryIOS:(id)sender;
- (IBAction)selectPublishDirectoryAndroid:(id)sender;
- (IBAction)selectPackagePublishingCustomDirectory:(id)sender;

@end
