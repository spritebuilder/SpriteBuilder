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

@end