/*
	ImageAndTextCell.m
	Copyright © 2006, Apple Computer, Inc., all rights reserved.

	Subclass of NSTextFieldCell which can display text and an image simultaneously.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ImageAndTextCell.h"

static CGFloat IMAGE_PADDING_RIGHT = 3.0;

@implementation ImageAndTextCell

- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }

    [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    
    return self;
}

- copyWithZone:(NSZone *)zone
{
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
    cell.image = self.image;
    cell.imageAlt = self.imageAlt;
    return cell;
}

- (NSRect)imageAltFrameForCellFrame:(NSRect)cellFrame
{
    if (self.imageAlt != nil)
	{
        NSRect imageFrame;
        imageFrame.size = [self.imageAlt size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += cellFrame.size.width - 14.0;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
    {
        return NSZeroRect;
    }
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSRect titleRect = [self titleRectForBounds:aRect];
    titleRect.origin.x += [self.image size].width;
    [super editWithFrame:titleRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
    NSRect titleRect = [self titleRectForBounds:aRect];
    titleRect.origin.x += [self.image size].width;
    [super selectWithFrame:titleRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self drawImage:&cellFrame controlView:controlView];
    [self drawImageAlt:cellFrame controlView:controlView];

    [super drawWithFrame:cellFrame inView:controlView];
}

- (void)drawImageAlt:(NSRect)cellFrame controlView:(NSView *)controlView
{
    if (self.imageAlt == nil)
    {
        return;
    }

    [self.imageAlt setFlipped:[controlView isFlipped]];
    [self.imageAlt drawAtPoint:[self imageAltFrameForCellFrame:cellFrame].origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawImage:(NSRect *)cellFrame controlView:(NSView *)controlView
{
    if (self.image == nil)
	{
        return;
    }

    NSSize imageSize = [self.image size];
    NSRect imageFrame;
    NSDivideRect((*cellFrame), &imageFrame, cellFrame, IMAGE_PADDING_RIGHT + imageSize.width, NSMinXEdge);

    if ([self drawsBackground])
    {
        [[self backgroundColor] set];
        NSRectFill(imageFrame);
    }

    imageFrame.origin.x += IMAGE_PADDING_RIGHT;
    imageFrame.origin.y += 2;

    [self.image setFlipped:[controlView isFlipped]];
    [self.image drawAtPoint:imageFrame.origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (NSRect)titleRectForBounds:(NSRect)theRect
{
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSAttributedString *attrString = self.attributedStringValue;

    NSRect textRect = [attrString boundingRectWithSize:titleFrame.size
                                               options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin];

    if (textRect.size.height < titleFrame.size.height)
    {
        titleFrame.origin.y = theRect.origin.y + (theRect.size.height - textRect.size.height) / 2.0;
        titleFrame.size.height = textRect.size.height;
    }
    titleFrame.origin.x += IMAGE_PADDING_RIGHT;

    return titleFrame;
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}

- (NSAttributedString *)attributedStringValue
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = self.font;

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:[self lineBreakMode]];
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;

    if ([self isHighlighted])
    {
        attributes[NSForegroundColorAttributeName] = [NSColor whiteColor];
    }

    return [[NSAttributedString alloc] initWithString:[self stringValue] attributes:attributes];
}

- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width += (self.image ? [self.image size].width : 0) + IMAGE_PADDING_RIGHT;
    return cellSize;
}

- (NSColor*) highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    return NULL;
}

@end

