//
//  StringPropertySetter.h
//  SpriteBuilder
//
//  Created by Viktor on 8/9/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface StringPropertySetter : NSObject

+ (void) refreshStringProp:(NSString*)prop forNode:(CCNode*)node;

+ (void) setString:(NSString*)str forNode:(CCNode*)node andProp:(NSString*)prop;
+ (NSString*) stringForNode:(CCNode*)node andProp:(NSString*)prop;

+ (void) setLocalized:(BOOL)localized forNode:(CCNode*)node andProp:(NSString*)prop;
+ (BOOL) isLocalizedNode:(CCNode*)node andProp:(NSString*)prop;

+ (BOOL) hasTranslationForNode:(CCNode*)node andProp:(NSString*)prop;
+ (void) refreshAllStringProps;

@end
