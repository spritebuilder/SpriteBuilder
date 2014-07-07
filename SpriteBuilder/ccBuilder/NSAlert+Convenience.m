#import "NSAlert+Convenience.h"

@implementation NSAlert (Convenience)

+ (void)showModalDialogWithTitle:(NSString *)title message:(NSString *)msg
{
    NSAlert *alert = [NSAlert alertWithMessageText:title
                                     defaultButton:@"OK"
                                   alternateButton:NULL
                                       otherButton:NULL
                         informativeTextWithFormat:@"%@", msg];

    [alert runModal];
}

+ (void)showModalDialogWithTitle:(NSString *)title htmlBodyText:(NSString *)htmlBodyText
{
    NSAlert *alert = [NSAlert alertWithTitle:title htmlBodyText:htmlBodyText];
    [alert runModal];
}

+ (NSAlert *)alertWithTitle:(NSString *)title htmlBodyText:(NSString *)htmlBodyText
{
    NSString *htmlMessage =
            [NSString stringWithFormat:
                    @"<html><head><style>* {font-family: \"Lucida Grande\", sans-serif; padding:0; margin:0;}</style></head><body>"
                     "%@"
                     "</body></html>", htmlBodyText];

    NSDictionary *textAttributes;
    NSAttributedString *formattedString = [[NSAttributedString alloc] initWithHTML:[htmlMessage dataUsingEncoding:NSUTF8StringEncoding]
                                                                documentAttributes:&textAttributes];
    return [NSAlert alertWithTitle:title formattedText:formattedString];
}


# pragma mark - helper

+ (NSAlert *)alertWithTitle:(NSString *)title formattedText:(NSAttributedString *)text
{
    NSTextView *accessory = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 280, 15)];
    [accessory setTextContainerInset:NSMakeSize(-4.0, 0.0)];

    [accessory insertText:text];
    [accessory setEditable:NO];
    [accessory setSelectable:YES];
    [accessory setDrawsBackground:NO];

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    [alert setAccessoryView:accessory];

    accessory.backgroundColor = [NSColor redColor];

    return alert;
}

@end