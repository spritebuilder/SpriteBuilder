/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <MacTypes.h>
#import "ResourceManagerOutlineHandler.h"
#import "ImageAndTextCell.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "CCBGlobals.h"
#import "ResourceManagerPreviewView.h"
#import "NSPasteboard+CCB.h"
#import "CCBWarnings.h"
#import "ProjectSettings.h"
#import "MiscConstants.h"
#import "SBErrors.h"
#import "FeatureToggle.h"
#import "RMResource.h"
#import "ResourceTypes.h"
#import "RMDirectory.h"
#import "RMSpriteFrame.h"
#import "RMAnimation.h"
#import "RMPackage.h"
#import "AppDelegate.h"
#import "NSString+Packages.h"
#import "PackageRenamer.h"
#import "PackageImporter.h"

@implementation ResourceManagerOutlineHandler

@synthesize resType;

- (id) initWithOutlineView:(NSOutlineView*)outlineView resType:(int)rt preview:(ResourceManagerPreviewView*)p
{
    self = [super init];
    if (!self) return NULL;
    
    resManager = [ResourceManager sharedManager];
    [resManager addResourceObserver:self];
    
    resourceList = outlineView;
    imagePreview = p;
    resType = rt;
    
    ImageAndTextCell* imageTextCell = [[ImageAndTextCell alloc] init];
    [imageTextCell setEditable:YES];
    [[resourceList outlineTableColumn] setDataCell:imageTextCell];
    [[resourceList outlineTableColumn] setEditable:YES];
    
    [resourceList setDataSource:self];
    [resourceList setDelegate:self];
    [resourceList setTarget:self];
    [resourceList setDoubleAction:@selector(doubleClicked:)];
    
    [outlineView registerForDraggedTypes:[NSArray arrayWithObjects:@"com.cocosbuilder.RMResource", NSFilenamesPboardType, nil]];
    
    return self;
}

- (void) reload
{
    [resourceList reloadData];
}



- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    // Do not display directories if only one directory is used
    if (item == NULL && [resManager.activeDirectories count] == 1)
    {
        item = [resManager.activeDirectories objectAtIndex:0];
    }
    
    // Handle base nodes
    if (item == NULL)
    {
        return [resManager.activeDirectories count];
    }
    
    // Fetch the data object of directory resources and use it as the item object
    if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
        if (res.type == kCCBResTypeDirectory)
        {
            item = res.data;
        }
    }
    
    // Handle different nodes
    if ([item isKindOfClass:[RMDirectory class]])
    {
        RMDirectory* dir = item;
        
        NSArray* children = [dir resourcesForType:resType];
        return [children count];
    }
    else if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
        if (res.type == kCCBResTypeSpriteSheet)
        {
            NSArray* frames = res.data;
            return [frames count];
        }
        else if (res.type == kCCBResTypeAnimation)
        {
            NSArray* anims = res.data;
            return [anims count];
        }
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    // Do not display directories if only one directory is used
    if (item == NULL && [resManager.activeDirectories count] == 1)
    {
        item = [resManager.activeDirectories objectAtIndex:0];
    }
    
    // Return base nodes
    if (item == NULL)
    {
        return [resManager.activeDirectories objectAtIndex:index];
    }
    
    // Fetch the data object of directory resources and use it as the item object
    if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
        if (res.type == kCCBResTypeDirectory)
        {
            item = res.data;
        }
    }
    
    // Return children for different nodes
    if ([item isKindOfClass:[RMDirectory class]])
    {
        RMDirectory* dir = item;
        NSArray* children = [dir resourcesForType:resType];
        return [children objectAtIndex:index];
    }
    else if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
        if (res.type == kCCBResTypeSpriteSheet)
        {
            NSArray* frames = res.data;
            return [frames objectAtIndex:index];
        }
        else if (res.type == kCCBResTypeAnimation)
        {
            NSArray* anims = res.data;
            return [anims objectAtIndex:index];
        }
    }
    
    return NULL;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    // Do not display directories if only one directory is used
    if (item == NULL && [resManager.activeDirectories count] == 1)
    {
        item = [resManager.activeDirectories objectAtIndex:0];
    }
    
    if ([item isKindOfClass:[RMDirectory class]])
    {
        return YES;
    }
    else if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
        if (res.type == kCCBResTypeSpriteSheet) return YES;
        else if (res.type == kCCBResTypeAnimation) return YES;
        else if (res.type == kCCBResTypeDirectory) return YES;
    }
    
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[RMPackage class]])
    {
        RMPackage *package = item;
        return package.name;
    }
    else if ([item isKindOfClass:[RMDirectory class]])
    {
        RMDirectory* dir = item;
        return [dir.dirPath lastPathComponent];
    }
    else if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
        return [res.filePath lastPathComponent];
    }
    else if ([item isKindOfClass:[RMSpriteFrame class]])
    {
        RMSpriteFrame* sf = item;
        return sf.spriteFrameName;
    }
    else if ([item isKindOfClass:[RMAnimation class]])
    {
        RMAnimation* anim = item;
        return anim.animationName;
    }
    return @"";
}

- (NSImage*) smallIconForFile:(NSString*)file
{
    NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:file];
    [icon setScalesWhenResized:YES];
    icon.size = NSMakeSize(16, 16);
    return icon;
}

- (NSImage*) smallIconForFileType:(NSString*)type
{
    NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFileType:type];
    [icon setScalesWhenResized:YES];
    icon.size = NSMakeSize(16, 16);
    return icon;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSImage* icon = NULL;
    NSImage* warningIcon = NULL;

    if ([item isKindOfClass:[RMPackage class]])
    {
        icon = [self smallIconForFileType:PACKAGE_NAME_SUFFIX];
    }
    else if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
		// FIXME: Do all images by type
        if (res.type == kCCBResTypeImage)
        {
            icon = [self smallIconForFileType:@"png"];
        }
        else if (res.type == kCCBResTypeBMFont)
        {
            icon = [self smallIconForFileType:@"ttf"];
        }
        else
        {
            if (res.type == kCCBResTypeDirectory)
            {
                RMDirectory* dir = res.data;
                if (dir.isDynamicSpriteSheet)
                {
                    icon = [NSImage imageNamed:@"reshandler-spritesheet-folder.png"];
                }
                else
                {
                    icon = [self smallIconForFile:res.filePath];
                }
            }
            else
            {
                icon = [self smallIconForFile:res.filePath];
            }
        }
        
        // Add warning sign if there is a warning related to this file
        if ([_projectSettings.lastWarnings warningsForRelatedFile:res.relativePath])
        {
            warningIcon = [NSImage imageNamed:@"editor-warning.png"];
        }
    }
    else if ([item isKindOfClass:[RMSpriteFrame class]])
    {
        icon = [self smallIconForFileType:@"png"];
    }
    else if ([item isKindOfClass:[RMAnimation class]])
    {
        icon = [self smallIconForFileType:@"p12"];
    }
    [cell setImage:icon];
    [cell setImageAlt:warningIcon];
}


#pragma mark Dragging and dropping

- (BOOL) outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
    [pasteboard clearContents];
    
    NSMutableArray* pbItems = [NSMutableArray array];
    
    for (id item in items)
    {
        if ([item isKindOfClass:[RMResource class]])
        {
            [pbItems addObject:item];
        }
    }
    
    if ([pbItems count] > 0)
    {
        [pasteboard writeObjects:pbItems];
        return YES;
    }
    
    return NO;
}

- (NSDragOperation) outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    if (!item && [ResourceManager sharedManager].activeDirectories.count != 1)
    {
        return NSDragOperationNone;
    }

    if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
        if (res.type == kCCBResTypeDirectory)
        {
            // Drop on directories ok
            return NSDragOperationGeneric;
        }
        else
        {
            // Dropping on files not ok
            return NSDragOperationNone;
        }
    }
    if ([item isKindOfClass:[RMSpriteFrame class]])
    {
        // Drop on sprite frames not ok
        return NSDragOperationNone;
    }

    // Dropping on top level root ok
    return NSDragOperationGeneric;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
    if (!item && [ResourceManager sharedManager].activeDirectories.count != 1)
    {
        return NO;
    }

    // Get dropped items
    NSPasteboard* pasteboard = [info draggingPasteboard];

    // Find out the destination directory
    NSString* dstDir = NULL;
    if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = item;
        dstDir = res.filePath;
    }
    else if ([item isKindOfClass:[RMDirectory class]])
    {
        RMDirectory* dir = item;
        dstDir = dir.dirPath;
    }
    else if (item == NULL)
    {
        RMDirectory* dir = [[ResourceManager sharedManager].activeDirectories objectAtIndex:0];
        dstDir = dir.dirPath;
    }
    
    BOOL movedOrImportedFiles = NO;
    
    // Move files
    NSArray* pbRes = [pasteboard propertyListsForType:@"com.cocosbuilder.RMResource"];
    for (NSDictionary* dict in pbRes)
    {
        NSString* srcPath = [dict objectForKey:@"filePath"];
        int type = [[dict objectForKey:@"type"] intValue];
        
        movedOrImportedFiles |= [ResourceManager moveResourceFile:srcPath ofType:type toDirectory:dstDir];
    }
    
    // Import files & Packages
    NSArray* pbFilenames = [pasteboard propertyListForType:NSFilenamesPboardType];

    // Have packages been imported?
    movedOrImportedFiles |= [self importPackagesWithMixedPaths:pbFilenames];
    // NOTE: after importing packages, the array is reduced by these paths to allow
    // further importing of other resources
    pbFilenames = [self removePackagesFromPaths:pbFilenames];

    movedOrImportedFiles |= [ResourceManager importResources:pbFilenames intoDir:dstDir];
    
    // Make sure list is up-to-date
    if (movedOrImportedFiles)
    {
        [resourceList deselectAll:NULL];
        [[ResourceManager sharedManager] reloadAllResources];
    }
    
    return movedOrImportedFiles;
}


#pragma mark Importing Packages

- (BOOL)importPackagesWithMixedPaths:(NSArray *)paths
{
    NSError *error;
    PackageImporter *packageImporter = [[PackageImporter alloc] init];
    packageImporter.projectSettings = _projectSettings;
    if (![packageImporter importPackagesWithPaths:paths error:&error])
    {
        [self handleImportErrors:error];
        return NO;
    }
    return YES;
}

- (NSArray *)removePackagesFromPaths:(NSArray *)paths
{
    if (!paths)
    {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:paths.count];
    for (NSString *path in paths)
    {
        if (![path hasPackageSuffix])
        {
            [result addObject:path];
        }
    }

    return result;
}

- (void)handleImportErrors:(NSError *)error
{
    NSMutableString *errorMessage = [NSMutableString string];
    NSArray *errors = error.userInfo[@"errors"];
    for (NSError *anError in errors)
    {
        if (anError.code != SBDuplicateResourcePathError)
        {
            [errorMessage appendFormat:@"%@\n", anError.localizedDescription];
        }
    }

    if (errorMessage.length > 0)
    {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error"
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", errorMessage];
        [alert runModal];
    }
}

#pragma mark Selections and edit

- (void) outlineViewSelectionDidChange:(NSNotification *)notification
{
    [self updateSelectionPreview];
}

- (void) updateSelectionPreview
{
    id selection = [resourceList itemAtRow:[resourceList selectedRow]];
    [imagePreview setPreviewFile:selection];
    [resourceList setNeedsDisplay];
}

- (void) doubleClicked:(id)sender
{
    id item = [resourceList itemAtRow:[resourceList clickedRow]];
    
    if ([item isKindOfClass:[RMResource class]])
    {
        RMResource* res = (RMResource*) item;
        if (res.type == kCCBResTypeCCBFile)
        {
            [[AppDelegate appDelegate] openFile: res.filePath];
        }
    }
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return [item isKindOfClass:[RMResource class]]
            || [item isKindOfClass:[RMPackage class]];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSOutlineView *outlineView = (NSOutlineView *)control;

    id item = [outlineView itemAtRow:outlineView.editedRow];

    if ([item isKindOfClass:[RMPackage class]])
    {
        PackageRenamer *packageRenamer = [[PackageRenamer alloc] init];
        packageRenamer.projectSettings = _projectSettings;
        NSError *error;
        if (![packageRenamer canRenamePackage:item toName:fieldEditor.string error:&error])
        {
            [[NSAlert alertWithMessageText:@"Error"
                             defaultButton:@"OK"
                           alternateButton:nil
                               otherButton:nil
                 informativeTextWithFormat:@"%@", error.localizedDescription] runModal];
            return NO;
        }
    }
    return YES;
}

- (void) outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[RMResource class]])
    {
        RMResource *res = item;

        NSString *oldPath = res.filePath;
        NSString *oldExt = [[oldPath pathExtension] lowercaseString];

        NSString *newName = object;
        NSString *newExt = [[newName pathExtension] lowercaseString];

        // Make sure we have a valid extension
        if (!newExt || ![oldExt isEqualToString:newExt])
        {
            newName = [newName stringByAppendingPathExtension:oldExt];
        }

        // Make sure that the name is a valid file name
        newName = [newName stringByReplacingOccurrencesOfString:@"/" withString:@""];

        if (newName && [newName length] > 0)
        {
            // Rename the file
            [ResourceManager renameResourceFile:oldPath toNewName:newName];
        }
    }
    else if ([item isKindOfClass:[RMPackage class]])
    {
        PackageRenamer *packageRenamer = [[PackageRenamer alloc] init];
        packageRenamer.projectSettings = _projectSettings;
        packageRenamer.resourceManager = [ResourceManager sharedManager];
        NSString *newName = object;
        NSError *error;
        if (![packageRenamer renamePackage:item toName:newName error:&error])
        {
            [[NSAlert alertWithMessageText:@"Error"
                             defaultButton:@"OK"
                           alternateButton:nil
                               otherButton:nil
                 informativeTextWithFormat:@"%@", error.localizedDescription] runModal];
        }
    }

    [resourceList deselectAll:NULL];
}

- (void) resourceListUpdated
{
    [resourceList reloadData];
}

- (void) setResType:(int)rt
{
    resType = rt;
    [resourceList reloadData];
}


@end
