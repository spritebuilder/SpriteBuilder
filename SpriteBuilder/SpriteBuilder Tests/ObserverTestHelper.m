#import <OCMock/OCMock.h>

#import "ObserverTestHelper.h"

@implementation ObserverTestHelper

+ (id)observerMockForNotification:(NSString *)notificationName
{
    id observerMock = [OCMockObject observerMock];

    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:notificationName object:nil];
    [[observerMock expect] notificationWithName:notificationName object:[OCMArg any]];

    return observerMock;
}

+ (void)verifyAndRemoveObserverMock:(id)observerMock
{
    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}


@end