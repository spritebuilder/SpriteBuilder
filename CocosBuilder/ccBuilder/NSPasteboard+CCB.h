//
//  NSPasteboard+CCB.h
//  CocosBuilder
//
//  Created by Viktor on 6/20/13.
//
//

#import <Cocoa/Cocoa.h>

@interface NSPasteboard (CCB)

- (NSArray*) propertyListsForType:(NSString*) type;

@end
