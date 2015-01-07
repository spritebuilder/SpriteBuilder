//
//  SecurityScopedBookmarksStore.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 07.01.15.
//
//

#import "SecurityScopedBookmarksStore.h"
#import "SBUserDefaultsKeys.h"

@implementation SecurityScopedBookmarksStore

+ (void)createAndStoreBookmarkForURL:(NSURL *)url
{
    NSError *error;
    NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                 includingResourceValuesForKeys:nil
                                  relativeToURL:nil
                                          error:&error];
    if (data)
    {
        NSMutableDictionary *bookmarks = [[[NSUserDefaults standardUserDefaults] objectForKey:SECURITY_SCOPED_BOOKMARKS_KEY] mutableCopy];
        if (!bookmarks)
        {
            bookmarks = [NSMutableDictionary dictionary];
        }
        
        bookmarks[url.path] = data;
        
        [[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:SECURITY_SCOPED_BOOKMARKS_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else
    {
        NSLog(@"Error generating security scoped bookmark for %@ with error %@", url, error);
    }
}

+ (NSURL *)resolveBookmarkForURL:(NSURL *)url
{
    NSMutableDictionary *bookmarks = [[[NSUserDefaults standardUserDefaults] objectForKey:SECURITY_SCOPED_BOOKMARKS_KEY] mutableCopy];
    NSData *bookmarkData = bookmarks[url.path];
    if (!bookmarks || !bookmarkData)
    {
        return nil;
    }

    BOOL isStale;
    NSError *error;
    NSURL *bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmarkData
                                                   options:NSURLBookmarkResolutionWithSecurityScope
                                             relativeToURL:nil
                                       bookmarkDataIsStale:&isStale
                                                     error:&error];

    if (isStale)
    {
        return nil;
    }

    if (!bookmarkURL)
    {
        NSLog(@"Error resolving bookmark data for project path %@ - %@", url.path, error);
        return nil;
    }

    return bookmarkURL;
}

@end
