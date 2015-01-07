//
//  SecurityScopedBookmarksStore.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 07.01.15.
//
//

#import <Foundation/Foundation.h>

@interface SecurityScopedBookmarksStore : NSObject

+ (void)createAndStoreBookmarkForURL:(NSURL *)url;

// Returns a URL if a non stale bookmark is stored for a given url
+ (NSURL *)resolveBookmarkForURL:(NSURL *)url;

@end
