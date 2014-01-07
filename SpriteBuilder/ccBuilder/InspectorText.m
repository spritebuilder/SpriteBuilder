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

#import "InspectorText.h"
#import "StringPropertySetter.h"
#import "AppDelegate.h"
#import "CocosScene.h"
#import "LocalizationEditorHandler.h"

@implementation InspectorText

- (void) setText:(NSAttributedString *)text
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    NSString* str = [text string];
    if (!str) str = @"";
    
    [StringPropertySetter setString:str forNode:selection andProp:propertyName];
    
    [self updateAffectedProperties];
    
    [self willChangeValueForKey:@"hasTranslation"];
    [self didChangeValueForKey:@"hasTranslation"];
}

- (NSAttributedString*) text
{
    NSString* str = [StringPropertySetter stringForNode:selection andProp:propertyName];
    return [[NSAttributedString alloc] initWithString:str];
}

- (void)controlTextDidChange:(NSNotification *)note
{
    NSTextField * changedField = [note object];
    [self setText:[changedField attributedStringValue]];
}

- (void) setLocalize:(BOOL)localize
{
    [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:propertyName];
    
    [StringPropertySetter setLocalized:localize forNode:selection andProp:propertyName];
    
    [self updateAffectedProperties];
}

- (BOOL) localize
{
    return [StringPropertySetter isLocalizedNode:selection andProp:propertyName];
}

- (BOOL) hasTranslation
{
    return [StringPropertySetter hasTranslationForNode:selection andProp:propertyName];
}

- (void) refresh
{
    [self willChangeValueForKey:@"text"];
    [self willChangeValueForKey:@"localize"];
    [self willChangeValueForKey:@"hasTranslation"];
    
    [self didChangeValueForKey:@"text"];
    [self didChangeValueForKey:@"localize"];
    [self didChangeValueForKey:@"hasTranslation"];
    
    [StringPropertySetter refreshStringProp:propertyName forNode:selection];
}

- (IBAction)pressedEditTranslation:(id)sender
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    [handler openEditor:sender];
    [handler createOrEditTranslationForKey:[[self text] string]];
}

@end
