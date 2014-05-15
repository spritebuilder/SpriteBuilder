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

#import "MainWindow.h"
#import "AppDelegate.h"
#import "CCBSplitHorizontalView.h"
#import "SBUserDefaultsKeys.h"

@implementation MainWindow


-(void)disableUpdatesUntilFlush
{
    if(!needsEnableUpdate)
        NSDisableScreenUpdates();
    needsEnableUpdate = YES;
}

-(void)flushWindow
{
    [super flushWindow];
    if(needsEnableUpdate)
    {
        needsEnableUpdate = NO;
        NSEnableScreenUpdates();
    }
}

-(IBAction)performClose:(id)sender
{
    [[AppDelegate appDelegate] performClose:sender];
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem.title isEqualToString:@"Close"])
    {
        return [[AppDelegate appDelegate] hasOpenedDocument];
    }
    return [super validateMenuItem:menuItem];
}

- (IBAction)pressedPanelVisibility:(id)sender
{
    NSSegmentedControl *sc = sender;
    [self disableUpdatesUntilFlush];

    NSRect mainRect = _splitHorizontalView.frame;
    // Left Panel
    if ([sc isSelectedForSegment:0])
    {

        if ([_leftPanel isHidden])
        {
            // Show left panel & shrink splitHorizontalView
            NSRect origRect = _leftPanel.frame;
            NSRect transitionFrame = NSMakeRect(0,
                                                origRect.origin.y,
                                                origRect.size.width,
                                                origRect.size.height);

            [_leftPanel setFrame:transitionFrame];
            mainRect = NSMakeRect(_leftPanel.frame.size.width,
                                  mainRect.origin.y,
                                  mainRect.size.width - _leftPanel.frame.size.width,
                                  mainRect.size.height);

            [_leftPanel setHidden:NO];
            [_leftPanel setNeedsDisplay:YES];
        }
    }
    else
    {

        if (![_leftPanel isHidden])
        {
            // Hide left panel & expand splitView
            NSRect origRect = _leftPanel.frame;
            NSRect transitionFrame = NSMakeRect(-origRect.size.width,
                                                origRect.origin.y,
                                                origRect.size.width,
                                                origRect.size.height);

            [_leftPanel setFrame:transitionFrame];
            mainRect = NSMakeRect(0,
                                  mainRect.origin.y,
                                  mainRect.size.width + _leftPanel.frame.size.width,
                                  mainRect.size.height);

            [_leftPanel setHidden:YES];
            [_leftPanel setNeedsDisplay:YES];
        }
    }


    // Right Panel (InspectorScroll)
    if ([sc isSelectedForSegment:2])
    {

        if ([_rightPanel isHidden])
        {
            // Show right panel & shrink splitView
            [_rightPanel setHidden:NO];
            NSRect origRect = _rightPanel.frame;
            NSRect transitionFrame = NSMakeRect(origRect.origin.x - origRect.size.width,
                                                origRect.origin.y,
                                                origRect.size.width,
                                                origRect.size.height);

            [_rightPanel setFrame:transitionFrame];
            mainRect = NSMakeRect(mainRect.origin.x,
                                  mainRect.origin.y,
                                  mainRect.size.width - _rightPanel.frame.size.width,
                                  mainRect.size.height);

            [_rightPanel setNeedsDisplay:YES];
        }
    }
    else
    {

        if (![_rightPanel isHidden])
        {
            // Hide right panel & expand splitView
            NSRect origRect = _rightPanel.frame;
            NSRect transitionFrame = NSMakeRect(origRect.origin.x + origRect.size.width,
                                                origRect.origin.y,
                                                origRect.size.width,
                                                origRect.size.height);

            [_rightPanel setFrame:transitionFrame];
            mainRect = NSMakeRect(mainRect.origin.x,
                                  mainRect.origin.y,
                                  mainRect.size.width + _rightPanel.frame.size.width,
                                  mainRect.size.height);

            [_rightPanel setHidden:YES];
            [_rightPanel setNeedsDisplay:YES];
        }
    }

    [_splitHorizontalView toggleBottomView:[sc isSelectedForSegment:1]];
    [_splitHorizontalView setFrame:mainRect];
    [_splitHorizontalView setNeedsDisplay:YES];
}

- (void)restorePreviousOpenedPanels
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [_panelVisibilityControl setSelected:[def boolForKey:LAST_VISIT_LEFT_PANEL_VISIBLE] forSegment:0];
    [_panelVisibilityControl setSelected:[def boolForKey:LAST_VISIT_BOTTOM_PANEL_VISIBLE] forSegment:1];
    [_panelVisibilityControl setSelected:[def boolForKey:LAST_VISIT_RIGHT_PANEL_VISIBLE] forSegment:2];
    [self pressedPanelVisibility:_panelVisibilityControl];
}

- (void)saveMainWindowPanelsVisibility
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[_panelVisibilityControl isSelectedForSegment:0] forKey:LAST_VISIT_LEFT_PANEL_VISIBLE];
    [defaults setBool:[_panelVisibilityControl isSelectedForSegment:1] forKey:LAST_VISIT_BOTTOM_PANEL_VISIBLE];
    [defaults setBool:[_panelVisibilityControl isSelectedForSegment:2] forKey:LAST_VISIT_RIGHT_PANEL_VISIBLE];
    [defaults synchronize];
}

@end
