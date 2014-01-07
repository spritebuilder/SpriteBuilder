/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2011 Viktor Lidholt
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

#import "NewDocWindowController.h"
#import "PlugInManager.h"
#import "ResolutionSetting.h"

@implementation NewDocWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (!self) return NULL;
    
    return self;
}

- (void) awakeFromNib
{
    [_btnScene setState:NSOnState];
    self.width = 0;
    self.height = 0;
    self.canSetSize = NO;
    
    self.documentName = @"Untitled.ccb";
    
    // Select only the Untitled word
    [documentNameField selectText:self];
    NSText* textEditor = [self.window fieldEditor:YES forObject:documentNameField];
    NSRange range = NSMakeRange(0, 8);
    [textEditor setSelectedRange:range];
}

- (IBAction)pressedObjectTypeButton:(id)sender
{
    NSButton* btn = sender;
    
    // Update button states
    [_btnScene setState:NSOffState];
    [_btnNode setState:NSOffState];
    [_btnLayer setState:NSOffState];
    [_btnSprite setState:NSOffState];
    [_btnParticleSystem setState:NSOffState];
    
    [btn setState:NSOnState];
    
    int objectType = btn.tag;
    self.rootObjectType = objectType;
    
    if (objectType == kCCBNewDocTypeScene)
    {
        // Scene
        self.canSetSize = NO;
        self.width = 0;
        self.height = 0;
    }
    else if (objectType == kCCBNewDocTypeNode)
    {
        // Node
        self.canSetSize = NO;
        self.width = 0;
        self.height = 0;
    }
    else if (objectType == kCCBNewDocTypeLayer)
    {
        // Layer
        self.canSetSize = YES;
        self.width = 568;
        self.height = 384;
    }
    else if (objectType == kCCBNewDocTypeSprite)
    {
        // Sprite
        self.canSetSize = NO;
        self.width = 0;
        self.height = 0;
    }
    else if (objectType == kCCBNewDocTypeParticleSystem)
    {
        // Particle system
        self.canSetSize = NO;
        self.width = 0;
        self.height = 0;
    }
}

-(NSMutableArray*) availableResolutions
{
    NSMutableArray* arr = [NSMutableArray array];
    
    if (self.rootObjectType == kCCBNewDocTypeLayer)
    {
        // Add resolutions
        ResolutionSetting* phoneSetting = [ResolutionSetting settingIPhone];
        phoneSetting.width = self.width;
        phoneSetting.height = self.height;
        
        [arr addObject: phoneSetting];
    }
    
    return arr;
}

- (IBAction)acceptSheet:(id)sender
{
    if ([[self window] makeFirstResponder:[self window]])
    {
        [NSApp stopModalWithCode:1];
        /*
        // Verify resolutions
        BOOL foundEnabledResolution = NO;
        for (ResolutionSetting* setting in resolutions)
        {
            if (setting.enabled) foundEnabledResolution = YES;
        }
        
        if (foundEnabledResolution)
        {
            [NSApp stopModalWithCode:1];
        }
        else
        {
            // Display warning!
            NSAlert* alert = [NSAlert alertWithMessageText:@"Missing Resolution" defaultButton:@"OK" alternateButton:NULL otherButton:NULL informativeTextWithFormat:@"You need to have at least one resolution enabled to create a new document."];
            [alert beginSheetModalForWindow:[self window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
        }*/
    }
}


- (IBAction)cancelSheet:(id)sender
{
    [NSApp stopModalWithCode:0];
}

- (void) dealloc
{
	SBLogSelf();
    self.rootObjectType = NULL;
}

@end
