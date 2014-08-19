//
//  LocalizationTransactionObserver.m
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 7/11/14.
//
//

#import "LocalizationTransactionObserver.h"
#import "LocalizationTranslateWindow.h"

@implementation LocalizationTransactionObserver
@synthesize ltw = _ltw;

/*
 * Observes and handles responses from the paymentQueue
 */
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
        
    for (SKPaymentTransaction* transaction in transactions)
    {
        switch(transaction.transactionState)
        {
            case SKPaymentTransactionStateFailed:
            {
                NSLog(@"Failed: %@", transaction.error);
                if(_ltw)
                {
                    [_ltw enableAll];
                    [_ltw setPaymentError];
                }
                else
                {
                    NSLog(@"No transaction window to process failure!!");
                }
                [queue finishTransaction:transaction];
                _ltw = nil;
                break;
            }
            case SKPaymentTransactionStatePurchased:
            {
                NSLog(@"Purchased");
                NSURL* receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                NSData* receipt = [NSData dataWithContentsOfURL:receiptURL];
                if(_ltw)
                {
                    [_ltw saveReceipt:receipt transaction:transaction];
                    [_ltw validateReceipt:[receipt base64EncodedStringWithOptions:0]];
                }
                else
                {
                    NSLog(@"No transaction window to process purchased!!");
                }
                [queue finishTransaction:transaction];
                _ltw = nil;
                break;
            }
            case SKPaymentTransactionStateRestored:
            {
                NSLog(@"Restored - Shouldn't happen");
                [queue finishTransaction:transaction];
                _ltw = nil;
                break;
            }
            default:
                break;
        }
    }
}
@end
