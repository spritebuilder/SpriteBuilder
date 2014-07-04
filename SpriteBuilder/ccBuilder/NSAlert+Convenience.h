#import <Foundation/Foundation.h>

@interface NSAlert (Convenience)

+ (void)showModalDialogWithTitle:(NSString *)title message:(NSString *)msg;

// Shows a dialog with text formatted as html. Provide the body tag's content.
// Helps to add hyperlinks and text formatting.
+ (void)showModalDialogWithTitle:(NSString *)title htmlBodyText:(NSString *)htmlBodyText;

@end