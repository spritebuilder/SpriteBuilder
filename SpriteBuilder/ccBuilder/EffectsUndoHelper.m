//
//  EffectsUndoHelper.m
//  SpriteBuilder
//
//  Created by Viktor on 9/26/14.
//
//

#import "EffectsUndoHelper.h"
#import "AppDelegate.h"

@implementation EffectsUndoHelper

+ (void) handleUndoForKey:(NSString*)key effect:(id<EffectProtocol>) effect
{
    NSArray* props = [effect serialize];
    for (NSDictionary* prop in props)
    {
        NSString* propName = [prop objectForKey:@"name"];
        if ([key isEqualToString:propName])
        {
            [[AppDelegate appDelegate] saveUndoStateWillChangeProperty:[NSString stringWithFormat:@"effect_%@",key]];
        }
    }
}

@end
