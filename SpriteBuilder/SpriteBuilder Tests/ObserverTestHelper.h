#import <Foundation/Foundation.h>

/** Helper class to reduce repetitive code when testing with OCMock and observers
 * Standard use pattern:
 *
 *      id observerMock = [ObserverTestHelper observerMockForNotification:RESOURCE_PATHS_CHANGED];
 *
 *      // DO TESTS...
 *
 *      [ObserverTestHelper verifyAndRemoveObserverMock:observerMock];
 */
@interface ObserverTestHelper : NSObject

// Returns a [OCMockObject observerMock] with expecting notificationName sent by [NSNotificationCenter defaultCenter]
// any object accepted
+ (id)observerMockForNotification:(NSString *)notificationName;

// Verifies and removes a [OCMockObject observerMock] from the [NSNotificationCenter defaultCenter]
+ (void)verifyAndRemoveObserverMock:(id)observerMock;

@end