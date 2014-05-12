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

#import "TaskStatusWindow.h"

@implementation TaskStatusWindow

@synthesize status;

- (IBAction)onCancel:(id)sender
{
    if (_onCancelBlock)
    {
        _onCancelBlock();
    }

    [cancelButton setTitle:@"Cancelling"];
    [cancelButton setEnabled:NO];
}

- (void) windowDidLoad
{
    [super windowDidLoad];
    [progressIndicator startAnimation:self];
    [progressIndicator setUsesThreadedAnimation:YES];

    self.showCancelButton = YES;
    if (_showCancelButton)
    {
        NSRect frame = [self.window frame];
        frame.size = CGSizeMake(frame.size.width, frame.size.height + 28.0);
        [self.window setFrame:frame display:YES animate:NO];
    }

    [progressIndicator setIndeterminate:self.indeterminate];
}

- (void)setIndeterminate:(BOOL)indeterminate
{
    _indeterminate = indeterminate;
    [progressIndicator setIndeterminate:indeterminate];
}


#pragma mark - TaskStatusProtocol methods

- (void)updateStatusText:(NSString *)text
{
    self.status = text;
}

- (void)setProgress:(double)newProgress
{
    [progressIndicator setDoubleValue:newProgress];
}

@end
