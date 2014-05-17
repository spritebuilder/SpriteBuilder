//
//  InspectorFloatCheck.m
//  SpriteBuilder
//
//  Created by John Twigg on 2/27/14.
//
//

#import "InspectorFloatCheck.h"

@implementation InspectorFloatCheck

- (void) setF:(float)f
{
    [self setPropertyForSelection:[NSNumber numberWithFloat:f]];
    [self performSelector:@selector(refresh) withObject:Nil afterDelay:0];
}

- (float) f
{
    return [[self propertyForSelection] floatValue];
}

-(void)setEnable:(BOOL)enable
{
    [selection setValue:@(enable) forKey:[NSString stringWithFormat:@"%@Enabled",propertyName]];
    [self refresh];
}

-(BOOL)enable
{
    return [[selection valueForKey:[NSString stringWithFormat:@"%@Enabled",propertyName]] boolValue];
}

- (void) refresh
{
    [self willChangeValueForKey:@"f"];
    [self didChangeValueForKey:@"f"];

    [super refresh];    
}

@end
