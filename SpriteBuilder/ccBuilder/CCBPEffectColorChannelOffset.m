    //
//  CCBPEffectColorChannelOffset.m
//  SpriteBuilder
//
//  Created by Thayer on 12/10/14.
//
//

#import "CCBPEffectColorChannelOffset.h"
#import "CCBReaderInternal.h"
#import "CCBWriterInternal.h"
#import "EffectsUndoHelper.h"

@implementation CCBPEffectColorChannelOffset

@synthesize UUID;

+ (CCEffect<CCEffectProtocol>*)defaultConstruct
{
    return [self effectWithRedOffset:GLKVector2Make(0.0f, 0.0f) greenOffset:GLKVector2Make(0.0f, 0.0f) blueOffset:GLKVector2Make(0.0f, 0.0f)];
}


- (id)serialize
{
    return @[@{@"name" : @"redOffsetWithPoint",   @"type" : @"Point", @"value": [CCBWriterInternal serializePoint:self.redOffsetWithPoint] },
             @{@"name" : @"greenOffsetWithPoint", @"type" : @"Point", @"value": [CCBWriterInternal serializePoint:self.greenOffsetWithPoint] },
             @{@"name" : @"blueOffsetWithPoint",  @"type" : @"Point", @"value": [CCBWriterInternal serializePoint:self.blueOffsetWithPoint] },
             ];
}

- (void)deserialize:(NSArray*)properties
{
    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"redOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.redOffsetWithPoint = [CCBReaderInternal deserializePoint:dict[@"value"]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"greenOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.greenOffsetWithPoint = [CCBReaderInternal deserializePoint:dict[@"value"]];
    }];

    [properties findFirst:^BOOL(NSDictionary * dict, int idx) {\
        return [dict[@"name"] isEqualToString:@"blueOffsetWithPoint"];\
    } complete:^(NSDictionary * dict, int idx) {
        
        self.blueOffsetWithPoint = [CCBReaderInternal deserializePoint:dict[@"value"]];
    }];
}

- (void)setRedOffsetX:(float)x
{
    CGPoint redOffset = self.redOffsetWithPoint;
    redOffset.x = x;
    self.redOffsetWithPoint = redOffset;
}

- (float)redOffsetX
{
    return self.redOffsetWithPoint.x;
}

- (void)setRedOffsetY:(float)y
{
    CGPoint redOffset = self.redOffsetWithPoint;
    redOffset.y = y;
    self.redOffsetWithPoint = redOffset;
}

- (float)redOffsetY
{
    return self.redOffsetWithPoint.y;
}

- (void)setGreenOffsetX:(float)x
{
    CGPoint greenOffset = self.greenOffsetWithPoint;
    greenOffset.x = x;
    self.greenOffsetWithPoint = greenOffset;
}

- (float)greenOffsetX
{
    return self.greenOffsetWithPoint.x;
}

- (void)setGreenOffsetY:(float)y
{
    CGPoint greenOffset = self.greenOffsetWithPoint;
    greenOffset.y = y;
    self.greenOffsetWithPoint = greenOffset;
}

- (float)greenOffsetY
{
    return self.greenOffsetWithPoint.y;
}

- (void)setBlueOffsetX:(float)x
{
    CGPoint blueOffset = self.blueOffsetWithPoint;
    blueOffset.x = x;
    self.blueOffsetWithPoint = blueOffset;
}

- (float)blueOffsetX
{
    return self.blueOffsetWithPoint.x;
}

- (void)setBlueOffsetY:(float)y
{
    CGPoint blueOffset = self.blueOffsetWithPoint;
    blueOffset.y = y;
    self.blueOffsetWithPoint = blueOffset;
}

- (float)blueOffsetY
{
    return self.blueOffsetWithPoint.y;
}

- (EffectDescription*)effectDescription
{
    return [EffectsManager effectByClassName: NSStringFromClass([self class])];
}

- (void)willChangeValueForKey:(NSString *)key
{
    if ([key hasPrefix:@"redOffset"])
    {
        key = @"redOffsetWithPoint";
    }
    if ([key hasPrefix:@"greenOffset"])
    {
        key = @"greenOffsetWithPoint";
    }
    if ([key hasPrefix:@"blueOffset"])
    {
        key = @"blueOffsetWithPoint";
    }
    
    [EffectsUndoHelper handleUndoForKey:key effect:self];
    [super willChangeValueForKey:key];
}

@end
