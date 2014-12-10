//
//  CCBPEffectLighting.m
//  SpriteBuilder
//
//  Created by Thayer J Andrews on 11/18/14.
//
//

#import "CCBPEffectLighting.h"
#import "CCBReaderInternal.h"
#import "CCBWriterInternal.h"
#import "EffectsManager.h"
#import "EffectsUndoHelper.h"

@implementation CCBPEffectLighting
@synthesize UUID;

+(CCEffect<CCEffectProtocol>*)defaultConstruct
{
    return [self effectWithGroups:nil specularColor:[CCColor whiteColor] shininess:10.0f];
}


-(id)serialize
{
    NSArray *groups = self.groups;
    if (!groups)
    {
        groups = @[];
    }
    
    return @[SERIALIZE_PROPERTY(shininess,Float),
             @{@"name" : @"groups", @"type" : @"TokenArray", @"value": groups },
             @{@"name" : @"specularColor", @"type" : @"Color4", @"value": [CCBWriterInternal serializeColor4:self.specularColor] },
             ];
}

-(void)deserialize:(NSArray*)properties
{
    DESERIALIZE_PROPERTY(shininess, floatValue);

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"groups"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        NSArray *serializedGroups = dict[@"value"];
        self.groups = serializedGroups;
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"specularColor"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.specularColor = [CCBReaderInternal deserializeColor4:dict[@"value"]];
    }];
}

-(void)setEditedColor:(NSColor *)editedColor
{
    NSColor *rgbColor = [editedColor colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    self.specularColor = [CCColor colorWithRed:rgbColor.redComponent green:rgbColor.greenComponent blue:rgbColor.blueComponent alpha:rgbColor.alphaComponent];
}

- (NSColor*)editedColor
{
    return self.specularColor.NSColor;
}

-(EffectDescription*)effectDescription
{
    return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

- (void) willChangeValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"editedColor"])
    {
        key = @"specularColor";
    }
    
    [EffectsUndoHelper handleUndoForKey:key effect:self];
    [super willChangeValueForKey:key];
}

@end
