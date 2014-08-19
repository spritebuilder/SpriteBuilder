//
//  LocalizationTransactionObserver.h
//  SpriteBuilder
//
//  Created by Benjamin Koatz on 7/11/14.
//
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
@class LocalizationTranslateWindow;

@interface LocalizationTransactionObserver : NSObject <SKPaymentTransactionObserver>
{
    LocalizationTranslateWindow* _ltw;
}
@property (nonatomic,strong) LocalizationTranslateWindow* ltw;

@end
