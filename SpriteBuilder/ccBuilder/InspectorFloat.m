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

#import "InspectorFloat.h"

@implementation InspectorFloat

- (id) initWithSelection:(CCNode *)s andPropertyName:(NSString *)pn andDisplayName:(NSString *)dn andExtra:(NSString *)e
{
    self = [super initWithSelection:s andPropertyName:pn andDisplayName:dn andExtra:e];
    if (!self) return NULL;
    
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];

    NSMutableDictionary *extraDict = [[NSMutableDictionary alloc] init];
    NSArray* extraParts = [self.extra componentsSeparatedByString:@"|"];
    NSUInteger pairCount = (extraParts.count / 2);
    for (NSUInteger pairIndex = 0; pairIndex < pairCount; pairIndex++)
    {
        NSString *key = extraParts[2 * pairIndex];
        NSString *value = extraParts[2 * pairIndex + 1];
        extraDict[key] = value;
    }

    // Get the cell from the text field and get the formatter from that.
    NSTextFieldCell *textFieldCell = (NSTextFieldCell *) textField.cell;
    NSNumberFormatter *numberFormatter = (NSNumberFormatter *) textFieldCell.formatter;
    
    if ((extraDict[@"min"] || extraDict[@"max"]) && numberFormatter)
    {
        NSNumberFormatter *stringConverter = [[NSNumberFormatter alloc] init];
        if (extraDict[@"min"])
        {
            numberFormatter.minimum = [stringConverter numberFromString:extraDict[@"min"]];
        }
        if (extraDict[@"max"])
        {
            numberFormatter.maximum = [stringConverter numberFromString:extraDict[@"max"]];
        }
    }
}

- (void) setF:(float)f
{
    [self setPropertyForSelection:[NSNumber numberWithFloat:f]];
}

- (float) f
{
    return [[self propertyForSelection] floatValue];
}

- (void) refresh
{
    [self willChangeValueForKey:@"f"];
    [self didChangeValueForKey:@"f"];

    [super refresh];
}

@end
