/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "CCBXCocos2diPhoneWriter.h"
#import "SequencerKeyframe.h"
#import "SequencerKeyframeEasing.h"
#import "CustomPropSetting.h"
#import "NSArray+Query.h"
@implementation CCBXCocos2diPhoneWriter

@synthesize data;
@synthesize flattenPaths;
@synthesize serializedProjectSettings;

- (void) setupPropTypes
{
    propTypes = [[NSMutableArray alloc] init];
    
    [propTypes addObject:@"Position"];
    [propTypes addObject:@"Size"];
    [propTypes addObject:@"Point"];
    [propTypes addObject:@"PointLock"];
    [propTypes addObject:@"ScaleLock"];
    [propTypes addObject:@"Degrees"];
    [propTypes addObject:@"Integer"];
    [propTypes addObject:@"Float"];
    [propTypes addObject:@"FloatVar"];
    [propTypes addObject:@"Check"];
    [propTypes addObject:@"SpriteFrame"];
    [propTypes addObject:@"Texture"];
    [propTypes addObject:@"Byte"];
    [propTypes addObject:@"Color3"];
    [propTypes addObject:@"Color4FVar"];
    [propTypes addObject:@"Flip"];
    [propTypes addObject:@"Blendmode"];
    [propTypes addObject:@"FntFile"];
    [propTypes addObject:@"Text"];
    [propTypes addObject:@"FontTTF"];
    [propTypes addObject:@"IntegerLabeled"];
    [propTypes addObject:@"Block"];
    [propTypes addObject:@"Animation"];
    [propTypes addObject:@"CCBFile"];
    [propTypes addObject:@"String"];
    [propTypes addObject:@"BlockCCControl"];
    [propTypes addObject:@"FloatScale"];
    [propTypes addObject:@"FloatXY"];
    [propTypes addObject:@"Color4"];
    [propTypes addObject:@"NodeReference"];
    [propTypes addObject:@"FloatCheck"];
}

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    data = [[NSMutableData alloc] init];
    stringCacheLookup = [[NSMutableDictionary alloc] init];
    [self setupPropTypes];
    
    return self;
}


- (int) propTypeIdForName:(NSString*)prop
{
    NSInteger propType = [propTypes indexOfObject:prop];
    if (propType == NSNotFound)
    {
        if([prop isEqualToString:@"StringSimple"])
            return [self propTypeIdForName:@"String"];
		
		if([prop isEqualToString:@"EnabledFloat"])
			return [self propTypeIdForName:@"FloatCheck"];
    }
    return (int)propType;
}

- (void) addToStringCache:(NSString*) str isPath:(BOOL) isPath
{
    if (isPath && flattenPaths)
    {
        str = [str lastPathComponent];
    }
    
    // Check if it is already in the chache, if so add to it's count
    NSNumber* num = [stringCacheLookup objectForKey:str];
    if (num)
    {
        num = [NSNumber numberWithInt:[num intValue]+1];
    }
    else
    {
        num = [NSNumber numberWithInt:1];
    }
    [stringCacheLookup setObject:num forKey:str];
}

- (void) writeBool:(BOOL)b
{
    unsigned char bytes[1];
    
    if (b) bytes[0] = 1;
    else bytes[0] = 0;
    
    [data appendBytes:bytes length:1];
}

- (void) writeByte:(unsigned char)b
{
    [data appendBytes:&b length:1];
}

-(NSString*)concatenateWithSeperator:(NSArray*)array seperator:(NSString*)seperator
{
	if(array == nil || array.count == 0)
		return @"";
	
	NSString * returnString = @"";
	for (NSString * item in array) {
		returnString = [returnString stringByAppendingString:item];
		returnString = [returnString stringByAppendingString:seperator];
	}
	//Remove tailing seperator.
	returnString = [returnString substringWithRange:NSMakeRange(0,returnString.length - seperator.length)];
	return returnString;
}

- (void) clearTempBuffer
{
    for (int i = 0; i < kCCBXTempBufferSize; i++) temp[i] = 0;
    tempBit = 0;
    tempByte = 0;
}

- (void) putBit:(BOOL)b
{
    if (b) temp[tempByte] |= 1 << tempBit;
    
    tempBit++;
    if (tempBit >= 8)
    {
        tempByte++;
        tempBit = 0;
    }
}

- (void) flushBits
{
    int numBytes = tempByte;
    if (tempBit != 0) numBytes++;
    
    [data appendBytes:temp length:numBytes];
}

// Encode integers using Elias Gamma encoding, pad with zeros up to next
// even byte. Handle negative values using bijection.
- (void) writeInt:(int)d withSign:(BOOL) sign
{
    [self clearTempBuffer];
    
    unsigned long long num;
    if (sign)
    {
        // Support for signed numbers
        long long dl = d;
        long long bijection;
        if (d < 0) bijection = (-dl)*2;
        else bijection = dl*2+1;
        num = bijection;
    }
    else
    {
        // Support for 0
        num = d+1;
    }
    
    NSAssert(num > 0, @"ccbi export: Trying to store negative int as unsigned");
    
    // Write number of bits used
    int l = log2(num);
    
    for (int a = 0; a < l; a++)
    {
        [self putBit:NO];
    }
    [self putBit:YES];
    
    // Write the actual number
    for (int a=l-1; a >= 0; a--)
    {
        if (num & 1 << a) [self putBit:YES];
        else [self putBit:NO];
    }
    [self flushBits];
}

- (void) writeFloat:(float)f
{
    unsigned char type;
    
    if (f == 0) type = kCCBXFloat0;
    else if (f == 1) type = kCCBXFloat1;
    else if (f == -1) type = kCCBXFloatMinus1;
    else if (f == 0.5f) type = kCCBXFloat05;
    else if (((int)f) == f) type = kCCBXFloatInteger;
    else type = kCCBXFloatFull;
    
    // Write the type
    [self writeByte:type];
    
    // Write the value
    if (type == kCCBXFloatInteger)
    {
        [self writeInt:f withSign:YES];
    }
    else if (type == kCCBXFloatFull)
    {
        [data appendBytes:&f length:4];
    }
}

- (void) writeUTF8:(NSString*)str
{
    unsigned long len = [str lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSAssert(len < 65536, @"ccbi export: Trying to write too long string");
    
    // Write Length of string
    unsigned char bytesLen[2];
    bytesLen[0] = (len >> 8) & 0xff;
    bytesLen[1] = len & 0xff;
    [data appendBytes:bytesLen length:2];
    
    // Write String as UTF8
    NSData *dataStr = [NSData dataWithBytes:[str UTF8String] length:len];
    [data appendData:dataStr];
}

- (void) writeCachedString:(NSString*) str isPath:(BOOL) isPath
{
    if (isPath && flattenPaths)
    {
        str = [str lastPathComponent];
    }
    
    NSNumber* num = [stringCacheLookup objectForKey:str];
    
    NSAssert(num, @"ccbi export: Trying to write string not added to cache (%@)", str);
    
    [self writeInt:[num intValue] withSign:NO];
}


- (void) writeProperty:(id) prop type:(NSString*)type name:(NSString*)name platform:(NSString*)platform
{
    int typeId = [self propTypeIdForName:type];
    NSAssert(typeId >= 0, @"ccbi export: Trying to write unkown property type %@",type);
    
    // Property type
    [self writeInt:typeId withSign:NO];
    
    // Property name
    [self writeCachedString:name isPath:NO];
    
    if ([type isEqualToString:@"Position"])
    {
        float x = [[prop objectAtIndex:0] floatValue];
        float y = [[prop objectAtIndex:1] floatValue];
        int corner = [[prop objectAtIndex:2] intValue];
        int xUnit = [[prop objectAtIndex:3] intValue];
        int yUnit = [[prop objectAtIndex:4] intValue];
        [self writeFloat:x];
        [self writeFloat:y];
        [self writeByte:corner];
        [self writeByte:xUnit];
        [self writeByte:yUnit];
    }
    else if([type isEqualToString:@"Size"])
    {
        float w = [[prop objectAtIndex:0] floatValue];
        float h = [[prop objectAtIndex:1] floatValue];
        int xUnit = [[prop objectAtIndex:2] intValue];
        int yUnit = [[prop objectAtIndex:3] intValue];
        [self writeFloat:w];
        [self writeFloat:h];
        [self writeByte:xUnit];
        [self writeByte:yUnit];
    }
    else if ([type isEqualToString:@"Point"]
             || [type isEqualToString:@"PointLock"]
             || [type isEqualToString:@"FloatVar"]
             || [type isEqualToString:@"FloatXY"])
    {
        float a = [[prop objectAtIndex:0] floatValue];
        float b = [[prop objectAtIndex:1] floatValue];
        [self writeFloat:a];
        [self writeFloat:b];
    }
    else if ([type isEqualToString:@"ScaleLock"])
    {
        float a = [[prop objectAtIndex:0] floatValue];
        float b = [[prop objectAtIndex:1] floatValue];
        int scaleType = 0;
        NSNumber* scaleTypeNum = [prop objectAtIndex:3];
        if (scaleTypeNum) scaleType = [scaleTypeNum intValue];

        [self writeFloat:a];
        [self writeFloat:b];
        [self writeByte:scaleType];
    }
    else if ([type isEqualToString:@"Degrees"]
             || [type isEqualToString:@"Float"])
    {
        float a = [prop floatValue];
        [self writeFloat:a];
    }
    else if ([type isEqualToString:@"FloatScale"])
    {
        float f = [[prop objectAtIndex:0] floatValue];
        int type = [[prop objectAtIndex:1] intValue];
        [self writeFloat:f];
        [self writeInt:type withSign:NO];
    }
    else if ([type isEqualToString:@"Integer"]
             || [type isEqualToString:@"IntegerLabeled"])
    {
        int a = [prop intValue];
        [self writeInt:a withSign:YES];
    }
    else if ([type isEqualToString:@"Byte"])
    {
        int a = [prop intValue];
        [self writeByte:a];
    }
    else if ([type isEqualToString:@"Check"])
    {
        BOOL a = [prop boolValue];
        [self writeBool:a];
    }
    else if ([type isEqualToString:@"SpriteFrame"])
    {
        NSString* a = [prop objectAtIndex:0];
        NSString* b = [prop objectAtIndex:1];
        
        if ([self isSprite:b inGeneratedSpriteSheet:a])
        {
            a = [[b stringByDeletingLastPathComponent] stringByAppendingPathExtension:@"plist"];
        }
        
        //[self writeCachedString:a isPath:YES];
        [self writeCachedString:b isPath:[a isEqualToString:@""]];
    }
    else if ([type isEqualToString:@"Animation"])
    {
        NSString* animationFile = [prop objectAtIndex:0];
        NSString* animation = [prop objectAtIndex:1];
        [self writeCachedString:animationFile isPath:YES];
        [self writeCachedString:animation isPath:NO];
    }
    else if ([type isEqualToString:@"Block"])
    {
        NSString* a = [prop objectAtIndex:0];
        NSNumber* b = [prop objectAtIndex:1];
        [self writeCachedString:a isPath:NO];
        [self writeInt:[b intValue] withSign:NO];
    }
    else if ([type isEqualToString:@"BlockCCControl"])
    {
        NSString* a = [prop objectAtIndex:0];
        NSNumber* b = [prop objectAtIndex:1];
        NSNumber* c = [prop objectAtIndex:2];
        [self writeCachedString:a isPath:NO];
        [self writeInt:[b intValue] withSign:NO];
        [self writeInt:[c intValue] withSign:NO];
    }
    else if ([type isEqualToString:@"Texture"]
             || [type isEqualToString:@"CCBFile"])
    {
        [self writeCachedString:prop isPath: YES];
    }
    else if ([type isEqualToString:@"FntFile"])
    {
        NSString* fntName = [[prop lastPathComponent] stringByDeletingPathExtension];
        NSString* path = [[prop stringByAppendingPathComponent:fntName] stringByAppendingPathExtension:@"fnt"];
        
        NSLog(@"FNT file: %@", path);
        
        [self writeCachedString:path isPath: YES];
    }
    else if ([type isEqualToString:@"Text"]
             || [type isEqualToString:@"String"]
             || [type isEqualToString:@"StringSimple"])
    {
        NSString* str = NULL;
        BOOL localized = NO;
        
        if ([prop isKindOfClass:[NSString class]])
        {
            str = prop;
        }
        else
        {
            str = [prop objectAtIndex:0];
            localized = [[prop objectAtIndex:1] boolValue];
        }
        if (!str) str = @"";
        
        [self writeCachedString:str isPath: NO];
        [self writeBool:localized];
    }
    else if ([type isEqualToString:@"FontTTF"])
    {
        [self writeCachedString:prop isPath: NO];
    }
    else if ([type isEqualToString:@"Color4"] ||
             [type isEqualToString:@"Color3"])
    {
        CGFloat a = [[prop objectAtIndex:0] floatValue];
        CGFloat b = [[prop objectAtIndex:1] floatValue];
        CGFloat c = [[prop objectAtIndex:2] floatValue];
        CGFloat d = [[prop objectAtIndex:3] floatValue];
        [self writeFloat:a];
        [self writeFloat:b];
        [self writeFloat:c];
        [self writeFloat:d];
    }
    else if ([type isEqualToString:@"Color4FVar"])
    {
        for (int i = 0; i < 2; i++)
        {
            NSArray* color = [prop objectAtIndex:i];
            for (int j = 0; j < 4; j++)
            {
                float comp = [[color objectAtIndex:j] floatValue];
                [self writeFloat:comp];
            }
        }
    }
    else if ([type isEqualToString:@"Flip"])
    {
        BOOL a = [[prop objectAtIndex:0] boolValue];
        BOOL b = [[prop objectAtIndex:1] boolValue];
        [self writeBool:a];
        [self writeBool:b];
    }
    else if ([type isEqualToString:@"Blendmode"])
    {
        int a = [[prop objectAtIndex:0] intValue];
        int b = [[prop objectAtIndex:1] intValue];
        [self writeInt:a withSign:NO];
        [self writeInt:b withSign:NO];
    }
    else if([type isEqualToString:@"NodeReference"])
    {
        [self writeInt:(int)[prop unsignedIntegerValue] withSign:NO];
    }
    else if([type isEqualToString:@"FloatCheck"] || [type isEqualToString:@"EnabledFloat"])
    {
        NSArray * propArray = (NSArray*)prop;
        [self writeFloat:[propArray[0] floatValue]];
        [self writeBool:[propArray[1] boolValue]];

    }
    else
    {
        NSLog(@"WARNING: Unknown property Type:%@" , type);
    }
}

-(void)cacheStringsForJoints:(NSArray*)joints
{
    for (NSDictionary * joint in joints) {
        [self cacheStringsForNode:joint];
    }
}

- (void) cacheStringsForNode:(NSDictionary*) node
{
    // Basic data
    [self addToStringCache:@"" isPath:NO];
    [self addToStringCache:[node objectForKey:@"baseClass"] isPath:NO];
    [self addToStringCache:[node objectForKey:@"customClass"] isPath:NO];
    [self addToStringCache:[node objectForKey:@"memberVarAssignmentName"] isPath:NO];
    
    // Animated properties
    NSDictionary* animatedProps = [node objectForKey:@"animatedProperties"];
    for (NSString* seqIdStr in animatedProps)
    {
        NSDictionary* props = [animatedProps objectForKey:seqIdStr];
        for (NSString* propName in props)
        {
            NSMutableDictionary* prop = [props objectForKey:propName];
            int kfType = [[prop objectForKey:@"type"] intValue];
            if (kfType == kCCBKeyframeTypeSpriteFrame)
            {
                NSArray* keyframes = [prop objectForKey:@"keyframes"];
                for (NSDictionary* keyframe in keyframes)
                {
                    // Write a keyframe
                    id value = [keyframe objectForKey:@"value"];
                    NSString* a = [value objectAtIndex:1];
                    NSString* b = [value objectAtIndex:0];
                    
                    if ([b isEqualToString:@"Use regular file"]) b = @"";
                    if ([a isEqualToString:@"Use regular file"]) a = @"";
                    
                    if ([self isSprite:b inGeneratedSpriteSheet:a])
                    {
                        a = [[b stringByDeletingLastPathComponent] stringByAppendingPathExtension:@"plist"];
                    }
                    
                    //[self addToStringCache:a isPath:YES];
                    [self addToStringCache:b isPath:[a isEqualToString:@""]];
                }
            }
        }
    }
    
    // Properties
    NSArray* props = [node objectForKey:@"properties"];
    for (int i = 0; i < [props count]; i++)
    {
        NSDictionary* prop = [props objectAtIndex:i];
        [self addToStringCache:[prop objectForKey:@"name"] isPath:NO];
        id value = [prop objectForKey:@"value"];
        
        NSString* type = [prop objectForKey:@"type"];
        
        id baseValue = [prop objectForKey:@"baseValue"];
        
        if (baseValue)
        {
            // We need to transform the base value to a normal value (base values override normal values)
            if ([type isEqualToString:@"Position"])
            {
                value = [NSArray arrayWithObjects:
                         [baseValue objectAtIndex:0],
                         [baseValue objectAtIndex:1],
                         [value objectAtIndex:2],
                         nil];
            }
            else if ([type isEqualToString:@"ScaleLock"])
            {
                value = [NSArray arrayWithObjects:
                         [baseValue objectAtIndex:0],
                         [baseValue objectAtIndex:1],
                         [NSNumber numberWithBool:NO],
                         [value objectAtIndex:3],
                         nil];
            }
            else if ([type isEqualToString:@"SpriteFrame"])
            {
                NSString* a = [baseValue objectAtIndex:0];
                NSString* b = [baseValue objectAtIndex:1];
                if ([b isEqualToString:@"Use regular file"]) b = @"";
                
                if ([self isSprite:a inGeneratedSpriteSheet:b])
                {
                    b = [[a stringByDeletingLastPathComponent] stringByAppendingPathExtension:@"plist"];
                }
                
                value = [NSArray arrayWithObjects:b, a, nil];
            }
            else
            {
                // Value needs no transformation
                value = baseValue;
            }
        }
        
        if ([type isEqualToString:@"SpriteFrame"])
        {
            NSString* a = [value objectAtIndex:0];
            NSString* b = [value objectAtIndex:1];
            
            if ([self isSprite:b inGeneratedSpriteSheet:a])
            {
                a = [[b stringByDeletingLastPathComponent] stringByAppendingPathExtension:@"plist"];
            }
            
            //[self addToStringCache: a isPath:YES];
            [self addToStringCache:b isPath:[a isEqualToString:@""]];
        }
		else if( [type isEqualToString:@"Animation"])
		{
            [self addToStringCache:[value objectAtIndex:0] isPath:YES];
            [self addToStringCache:[value objectAtIndex:1] isPath:NO];			
		}
        else if ([type isEqualToString:@"Block"])
        {
            [self addToStringCache:[value objectAtIndex:0] isPath:NO];
        }
        else if ([type isEqualToString:@"BlockCCControl"])
        {
            [self addToStringCache:[value objectAtIndex:0] isPath:NO];
        }
        else if ([type isEqualToString:@"Texture"]
                 || [type isEqualToString:@"CCBFile"])
        {
            [self addToStringCache:value isPath:YES];
        }
        else if ([type isEqualToString:@"FntFile"])
        {
            NSString* fntName = [[value lastPathComponent] stringByDeletingPathExtension];
            NSString* path = [[value stringByAppendingPathComponent:fntName] stringByAppendingPathExtension:@"fnt"];
            [self addToStringCache:path isPath:YES];
        }
        else if ([type isEqualToString:@"Text"]
                 || [type isEqualToString:@"String"]
                 || [type isEqualToString:@"StringSimple"] )
        {
            NSString* str = NULL;
            if ([value isKindOfClass:[NSString class]])
            {
                str = value;
            }
            else
            {
                str = [value objectAtIndex:0];
            }
            [self addToStringCache:str isPath:NO];
        }
        else if ([type isEqualToString:@"FontTTF"])
        {
            [self addToStringCache:value isPath:NO];
        }
    }
    
    // Custom properties
    NSArray* customProps = [node objectForKey:@"customProperties"];
    for (NSDictionary* customProp in customProps)
    {
        [self addToStringCache:[customProp objectForKey:@"name"] isPath:NO];
        
        int customType = [[customProp objectForKey:@"type"] intValue];
        if (customType == kCCBCustomPropTypeString)
        {
            [self addToStringCache:[customProp objectForKey:@"value"] isPath:NO];
        }
    }
    
    
    
    // Custom properties
    NSDictionary* physicsBodyProperties = [node objectForKey:@"physicsBody"];
   if(physicsBodyProperties)
   {
       NSString * collisionType = [physicsBodyProperties objectForKey:@"collisionType"];
       if(collisionType == nil)
       {
           collisionType = @"";
       }
  	   
	   NSString *	collisionCategoriesText = [self concatenateWithSeperator:[physicsBodyProperties objectForKey:@"collisionCategories"] seperator:@";"];
	   
	   NSString * collisionMaskText = [self concatenateWithSeperator:[physicsBodyProperties objectForKey:@"collisionMask"] seperator:@";"];
     
       [self addToStringCache:collisionType isPath:NO];
       [self addToStringCache:collisionCategoriesText isPath:NO];
       [self addToStringCache:collisionMaskText isPath:NO];
   }
    
    // Children
    NSArray* children = [node objectForKey:@"children"];
    for (int i = 0; i < [children count]; i++)
    {
        [self cacheStringsForNode:[children objectAtIndex:i]];
    }
}

- (void) cacheStringsForSequences:(NSDictionary*)doc
{
    NSArray* seqs = [doc objectForKey:@"sequences"];
    for (NSDictionary* seq in seqs)
    {
        [self addToStringCache:[seq objectForKey:@"name"] isPath:NO];
        
        // Write callback channel
        NSArray* callbackKeyframes = [[seq objectForKey:@"callbackChannel"] objectForKey:@"keyframes"];
        for (NSDictionary* kf in callbackKeyframes)
        {
            NSArray* value = [kf objectForKey:@"value"];
            NSString* callbackName = [value objectAtIndex:0];
            [self addToStringCache:callbackName isPath:NO];
        }
        
        NSArray* soundKeyframes = [[seq objectForKey:@"soundChannel"] objectForKey:@"keyframes"];
        for (NSDictionary* kf in soundKeyframes)
        {
            NSArray* value = [kf objectForKey:@"value"];
            NSString* soundName = [value objectAtIndex:0];
            [self addToStringCache:soundName isPath:YES];
        }
    }
}

- (void) writeChannelKeyframe:(NSDictionary*) kf
{
    NSArray* value = [kf objectForKey:@"value"];
    int type = [[kf objectForKey:@"type"] intValue];
    float time = [[kf objectForKey:@"time"] floatValue];
    
    [self writeFloat:time];
    
    if (type == kCCBKeyframeTypeCallbacks)
    {
        NSString* selector = [value objectAtIndex:0];
        int target = [[value objectAtIndex:1] intValue];
        
        [self writeCachedString:selector isPath:NO];
        [self writeInt:target withSign:NO];
    }
    else if (type == kCCBKeyframeTypeSoundEffects)
    {
        NSString* sound = [value objectAtIndex:0];
        float pitch = [[value objectAtIndex:1] floatValue];
        float pan = [[value objectAtIndex:2] floatValue];
        float gain = [[value objectAtIndex:3] floatValue];
        
        [self writeCachedString:sound isPath:YES];
        [self writeFloat:pitch];
        [self writeFloat:pan];
        [self writeFloat:gain];
    }
}

- (void) writeSequences:(NSDictionary*)doc
{
    NSArray* seqs = [doc objectForKey:@"sequences"];
    
    // Write number of sequences
    [self writeInt:(int)[seqs count] withSign:NO];

    //Write out if the docuement contains physics bodies.
    [self writeBool:[self hasPhysicsBodies:doc[@"nodeGraph"]]];
    
    //Write out if the document contains a physics node.
    [self writeBool:[self hasPhysicsNode:doc[@"nodeGraph"]]];
    

    
    int autoPlaySeqId = -1;
    
    // Write each sequence
    for (NSDictionary* seq in seqs)
    {
        [self writeFloat:[[seq objectForKey:@"length"] floatValue]];
        [self writeCachedString:[seq objectForKey:@"name"] isPath:NO];
        [self writeInt:[[seq objectForKey:@"sequenceId"] intValue] withSign:NO];
        [self writeInt:[[seq objectForKey:@"chainedSequenceId"] intValue] withSign:YES];
        
        // Check if autoplay is enabled
        if ([[seq objectForKey:@"autoPlay"] boolValue])
        {
            autoPlaySeqId = [[seq objectForKey:@"sequenceId"] intValue];
        }
        
        // Write callback channel
        NSArray* callbackKeyframes = [[seq objectForKey:@"callbackChannel"] objectForKey:@"keyframes"];
        
        [self writeInt: (int)callbackKeyframes.count withSign:NO];
        for (NSDictionary* keyframe in callbackKeyframes)
        {
            [self writeChannelKeyframe:keyframe];
        }
        
        // Write and sound channel
        NSArray* soundKeyframes = [[seq objectForKey:@"soundChannel"] objectForKey:@"keyframes"];
        
        [self writeInt: (int)soundKeyframes.count withSign:NO];
        for (NSDictionary* keyframe in soundKeyframes)
        {
            [self writeChannelKeyframe:keyframe];
        }
    }
    
    // Write autoPlay sequence (-1 for no autoplay)
    [self writeInt:autoPlaySeqId withSign:YES];
}

- (void) transformStringCache
{
    NSArray* stringCacheSorted = [stringCacheLookup keysSortedByValueUsingSelector:@selector(compare:)];
    
    NSMutableArray* stringCacheSortedReverse = [NSMutableArray arrayWithCapacity:[stringCacheSorted count]];
    
    NSEnumerator *enumerator = [stringCacheSorted reverseObjectEnumerator];
    for (id element in enumerator) {
        [stringCacheSortedReverse addObject:element];
    }
    
    // Clear the old cache and replace it with the new
    [stringCacheLookup removeAllObjects];
    
    for (int i = 0; i < [stringCacheSortedReverse count]; i++)
    {
        NSString* str = [stringCacheSortedReverse objectAtIndex:i];
        [stringCacheLookup setObject:[NSNumber numberWithInt:i] forKey:str];
    }
    
    stringCache = stringCacheSortedReverse;
}

- (void) writeHeader
{
    // Magic number
    int magic = 'ccbi';
    [data appendBytes:&magic length:4];
    
    // Version
    [self writeInt:kCCBXVersion withSign:NO];
}

- (void) writeStringCache
{
    [self writeInt:(int)[stringCache count] withSign:NO];
    
    for (int i = 0; i < [stringCache count]; i++)
    {
        [self writeUTF8:[stringCache objectAtIndex:i]];
    }
}

- (void) writeKeyframeValue:(id)value type: (NSString*)type time:(float)time easingType: (int)easingType easingOpt: (float)easingOpt
{
    // Write time
    [self writeFloat:time];
    
    // Write easing type
    [self writeInt:easingType withSign:NO];
    if (easingType == kCCBKeyframeEasingCubicIn
        || easingType == kCCBKeyframeEasingCubicOut
        || easingType == kCCBKeyframeEasingCubicInOut
        || easingType == kCCBKeyframeEasingElasticIn
        || easingType == kCCBKeyframeEasingElasticOut
        || easingType == kCCBKeyframeEasingElasticInOut)
    {
        [self writeFloat:easingOpt];
    }
    
    // Write value
    if ([type isEqualToString:@"Check"])
    {
        [self writeBool:[value boolValue]];
    }
    else if ([type isEqualToString:@"Byte"])
    {
        [self writeByte:[value intValue]];
    }
    else if ([type isEqualToString:@"Color4"] ||
             [type isEqualToString:@"Color3"])
    {
        float a = [[value objectAtIndex:0] floatValue];
        float b = [[value objectAtIndex:1] floatValue];
        float c = [[value objectAtIndex:2] floatValue];
        float d = [[value objectAtIndex:3] floatValue];
        [self writeFloat:a];
        [self writeFloat:b];
        [self writeFloat:c];
        [self writeFloat:d];
    }
    else if ([type isEqualToString:@"Degrees"] || [type isEqualToString:@"Float"])
    {
        [self writeFloat:[value floatValue]];
    }
    else if ([type isEqualToString:@"ScaleLock"]
             || [type isEqualToString:@"Position"]
             || [type isEqualToString:@"FloatXY"])
    {
        float a = [[value objectAtIndex:0] floatValue];
        float b = [[value objectAtIndex:1] floatValue];
        [self writeFloat:a];
        [self writeFloat:b];
    }
    else if ([type isEqualToString:@"SpriteFrame"])
    {
        NSString* a = [value objectAtIndex:1];
        NSString* b = [value objectAtIndex:0];
        
        if ([b isEqualToString:@"Use regular file"]) b = @"";
        if ([a isEqualToString:@"Use regular file"]) a = @"";
        
        if ([self isSprite:b inGeneratedSpriteSheet:a])
        {
            a = [[b stringByDeletingLastPathComponent] stringByAppendingPathExtension:@"plist"];
        }
        
        //[self writeCachedString:a isPath:YES];
        [self writeCachedString:b isPath:[a isEqualToString:@""]];
    }
}

-(BOOL)writeCodeConnections:(NSDictionary*)node
{
    // Write class
    NSString* class = [node objectForKey:@"customClass"];
    
    BOOL hasCustomClass = YES;
    if (!class || [class isEqualToString:@""])
    {
        class = [node objectForKey:@"baseClass"];
        hasCustomClass = NO;
    }
    [self writeCachedString:class isPath:NO];
    
    // Write assignment type and name
    int memberVarAssignmentType = [[node objectForKey:@"memberVarAssignmentType"] intValue];
    [self writeInt:memberVarAssignmentType withSign:NO];
    if (memberVarAssignmentType)
    {
        if([[node objectForKey:@"memberVarAssignmentName"] isEqualToString:@""])
        {
            
            [self.delegate addWarningWithDescription:[NSString stringWithFormat:@"Member ivar assigned with <blank> name. This will likely fail at runtime. Node %@", node[@"displayName"]] isFatal:NO relatedFile:Nil resolution:nil];
            
        }
        [self writeCachedString:[node objectForKey:@"memberVarAssignmentName"] isPath:NO];
    }
    
    return hasCustomClass;
}

- (void) writeNodeGraph:(NSDictionary*)node
{
    BOOL hasCustomClass = [self writeCodeConnections:node];
    
    // Write animated properties
    NSDictionary* animatedProps = [node objectForKey:@"animatedProperties"];
    
    // Animated sequences count
    [self writeInt:(int)[animatedProps count] withSign:NO];
    
    
    for (NSString* seqIdStr in animatedProps)
    {
        // Write a sequence
        
        int seqId = [seqIdStr intValue];
        [self writeInt:seqId withSign:NO];
        
        NSDictionary* props = [animatedProps objectForKey:seqIdStr];
        
        // Animated properties count
        [self writeInt:(int)[props count] withSign:NO];
        
        for (NSString* propName in props)
        {
            NSMutableDictionary* prop = [props objectForKey:propName];
            
            // Write a sequence node property
            [self writeCachedString:propName isPath:NO];
            
            // Write property type
            int kfType = [[prop objectForKey:@"type"] intValue];
            NSString* propType = NULL;
            if (kfType == kCCBKeyframeTypeToggle) propType = @"Check";
            else if (kfType == kCCBKeyframeTypeByte) propType = @"Byte";
            else if (kfType == kCCBKeyframeTypeColor3) propType = @"Color3";
            else if (kfType == kCCBKeyframeTypeColor4) propType = @"Color4";
            else if (kfType == kCCBKeyframeTypeDegrees) propType = @"Degrees";
            else if (kfType == kCCBKeyframeTypeScaleLock) propType = @"ScaleLock";
            else if (kfType == kCCBKeyframeTypeSpriteFrame) propType = @"SpriteFrame";
            else if (kfType == kCCBKeyframeTypePosition) propType = @"Position";
            else if (kfType == kCCBKeyframeTypeFloatXY) propType = @"FloatXY";
            else if (kfType == kCCBKeyframeTypeFloat) propType = @"Float";
            
            NSAssert(propType, @"Unknown animated property type");
            
            [self writeInt:[self propTypeIdForName:propType] withSign:NO];
            
            // Write number of keyframes
            NSArray* keyframes = [prop objectForKey:@"keyframes"];
            
            if (kfType == kCCBKeyframeTypeToggle && keyframes.count > 0)
            {
                BOOL visible = YES;
                NSDictionary* keyframeFirst = [keyframes objectAtIndex:0];
                if ([[keyframeFirst objectForKey:@"time"] floatValue] != 0)
                {
                    [self writeInt:(int)[keyframes count]+1 withSign:NO];
                    // Add a first keyframe
                    [self writeKeyframeValue:[NSNumber numberWithBool:NO] type:propType time:0 easingType:kCCBKeyframeEasingInstant easingOpt:0];
                }
                else
                {
                    [self writeInt:(int)[keyframes count] withSign:NO];
                }
                for (NSDictionary* keyframe in keyframes)
                {
                    float time = [[keyframe objectForKey:@"time"] floatValue];
                    [self writeKeyframeValue:[NSNumber numberWithBool:visible] type:propType time:time easingType:kCCBKeyframeEasingInstant easingOpt:0];
                    visible = !visible;
                }
                
            }
            else
            {
                [self writeInt:(int)[keyframes count] withSign:NO];
                
                for (NSDictionary* keyframe in keyframes)
                {
                    // Write a keyframe
                    id value = [keyframe objectForKey:@"value"];
                    float time = [[keyframe objectForKey:@"time"] floatValue];
                    NSDictionary* easing = [keyframe objectForKey:@"easing"];
                    int easingType = [[easing objectForKey:@"type"] intValue];
                    float easingOpt = [[easing objectForKey:@"opt"] floatValue];
                    
                    [self writeKeyframeValue:value type: propType time:time easingType: easingType easingOpt: easingOpt];
                }
            }
        }
    }
    
    // Write properties
    NSArray* props = [node objectForKey:@"properties"];
    NSArray* customProps = [node objectForKey:@"customProperties"];
    
    // Only write customProps if there is a custom class
    // or if the base class is a CCBFile to allow overwriting of custom properties
    if (!hasCustomClass && ![node[@"baseClass"] isEqualToString:@"CCBFile"])
    {
        customProps = [NSArray array];
    }

	// Sprite Kit requires certain properties to be exported in a specific order
	if ([_delegate exportingToSpriteKit])
	{
		NSMutableArray* sortedProps = [NSMutableArray arrayWithCapacity:props.count];
		for (NSDictionary* property in props)
		{
			// Sprite Frame should always be read first as it modifies (overrides) size & scale in Sprite Kit
			if ([[property objectForKey:@"name"] isEqualToString:@"spriteFrame"])
			{
				[sortedProps insertObject:property atIndex:0];
			}
			else
			{
				[sortedProps addObject:property];
			}
		}
		props = sortedProps;
	}
    
    NSUInteger uuid = [node[@"UUID"] unsignedIntegerValue];
    [self writeInt:(int)uuid withSign:NO];
    [self writeInt:(int)[props count] withSign:NO];
    [self writeInt:(int)[customProps count] withSign:NO];
    
    for (int i = 0; i < [props count]; i++)
    {
        NSDictionary* prop = [props objectAtIndex:i];
        
        id value = [prop objectForKey:@"value"];
        NSString* type = [prop objectForKey:@"type"];
        NSString* name = [prop objectForKey:@"name"];
        id baseValue = [prop objectForKey:@"baseValue"];
        
        if (baseValue)
        {
            // We need to transform the base value to a normal value (base values override normal values)
            if ([type isEqualToString:@"Position"])
            {
                value = [NSArray arrayWithObjects:
                         [baseValue objectAtIndex:0],
                         [baseValue objectAtIndex:1],
                         [value objectAtIndex:2],
                         [value objectAtIndex:3],
                         [value objectAtIndex:4],
                         nil];
            }
            else if ([type isEqualToString:@"ScaleLock"])
            {
                value = [NSArray arrayWithObjects:
                         [baseValue objectAtIndex:0],
                         [baseValue objectAtIndex:1],
                         [NSNumber numberWithBool:NO],
                         [value objectAtIndex:3],
                         nil];
            }
            else if ([type isEqualToString:@"SpriteFrame"])
            {
                NSString* a = [baseValue objectAtIndex:0];
                NSString* b = [baseValue objectAtIndex:1];
                if ([b isEqualToString:@"Use regular file"]) b = @"";
                
                if ([self isSprite:a inGeneratedSpriteSheet:b])
                {
                    b = [[a stringByDeletingLastPathComponent] stringByAppendingPathExtension:@"plist"];
                }
                
                value = [NSArray arrayWithObjects:b, a, nil];
            }
            else
            {
                // Value needs no transformation
                value = baseValue;
            }
        }
        
        [self writeProperty:value type:type name:name platform:[prop objectForKey:@"platform"]];
    }
    
    // Write custom properties
    for (NSDictionary* customProp in customProps)
    {
        int customType = [[customProp objectForKey:@"type"] intValue];
        NSString* customValue = [customProp objectForKey:@"value"];
        NSString* name = [customProp objectForKey:@"name"];
        
        NSString* type = NULL;
        id value = NULL;
        
        if (customType == kCCBCustomPropTypeInt)
        {
            type = @"Integer";
            value = [NSNumber numberWithInt:[customValue intValue]];
        }
        else if (customType == kCCBCustomPropTypeFloat)
        {
            type = @"Float";
            value = [NSNumber numberWithFloat:[customValue floatValue]];
        }
        else if (customType == kCCBCustomPropTypeBool)
        {
            type = @"Check";
            value = [NSNumber numberWithBool:[customValue boolValue]];
        }
        else if (customType == kCCBCustomPropTypeString)
        {
            type = @"String";
            value = customValue;
        }
        
        NSAssert(type, @"Failed to find custom type");
        
        [self writeProperty:value type:type name:name platform:nil];
    }
    
    // Write physics
    NSDictionary* physicsBody = [node objectForKey:@"physicsBody"];
    if (physicsBody)
    {
        [self writeBool:YES];
        
        // Shape
        int bodyShape = [[physicsBody objectForKey:@"bodyShape"] intValue];
        float cornerRadius = [[physicsBody objectForKey:@"cornerRadius"] floatValue];
        NSArray* points = [physicsBody objectForKey:@"points"];
        NSArray* polygons = [physicsBody objectForKey:@"polygons"];
        
        // Props
        BOOL dynamic = [[physicsBody objectForKey:@"dynamic"] boolValue];
        BOOL affectedByGravity = [[physicsBody objectForKey:@"affectedByGravity"] boolValue];
        BOOL allowsRotation = [[physicsBody objectForKey:@"allowsRotation"] boolValue];
        
        float density = [[physicsBody objectForKey:@"density"] floatValue];
        float friction = [[physicsBody objectForKey:@"friction"] floatValue];
        float elasticity = [[physicsBody objectForKey:@"elasticity"] floatValue];
        
        
        
        // Write physics body
        [self writeInt:bodyShape withSign:NO];
        [self writeFloat:cornerRadius];
        
        
        if(bodyShape == 1)
        {
            float x = [[points[0] objectAtIndex:0] floatValue];
            float y = [[points[0] objectAtIndex:1] floatValue];
            
            [self writeFloat:x];
            [self writeFloat:y];
        }
        else
        {
            [self writeInt:(int)polygons.count withSign:NO];
            for (NSArray * polygon in polygons)
            {
                [self writeInt:(int)polygon.count withSign:NO];
                for (NSArray* serPt in polygon)
                {
                    float x = [[serPt objectAtIndex:0] floatValue];
                    float y = [[serPt objectAtIndex:1] floatValue];
                    
                    [self writeFloat:x];
                    [self writeFloat:y];
                }
            }
        }
        
        [self writeBool:dynamic];
        [self writeBool:affectedByGravity];
        [self writeBool:allowsRotation];
        
        [self writeFloat:density];
        [self writeFloat:friction];
        [self writeFloat:elasticity];
        
		NSString * collisionType = [physicsBody objectForKey:@"collisionType"];
        NSArray * collisionCategories = [physicsBody objectForKey:@"collisionCategories"];
        NSArray * collisionMasks = [physicsBody objectForKey:@"collisionMask"];
		
		
        if(collisionType == nil)
        {
            collisionType = @"";
        }

		NSString *	collisionCategoriesText = [self concatenateWithSeperator:collisionCategories seperator:@";"];
		NSString * collisionMaskText = [self concatenateWithSeperator:collisionMasks seperator:@";"];
		
		[self writeCachedString:collisionType isPath:NO];
		[self writeCachedString:collisionCategoriesText isPath:NO];
		[self writeCachedString:collisionMaskText isPath:NO];
		 
    }
    else
    {
        [self writeBool:NO];
    }
    
    // Write children
    NSArray* children = [node objectForKey:@"children"];
    [self writeInt:(int)[children count] withSign:NO];
    for (int i = 0; i < [children count]; i++)
    {
        [self writeNodeGraph:[children objectAtIndex:i]];
    }
}

-(void)writeJoint:(NSDictionary*)joint
{
    NSString* class = [joint objectForKey:@"baseClass"];
    [self writeCachedString:class isPath:NO];
    
    NSArray * properties = joint[@"properties"];
    [self writeInt:(int)properties.count withSign:NO];
    
    for (NSDictionary* property in properties)
    {
        [self writeProperty:property[@"value"] type:property[@"type"] name:property[@"name"] platform:property[@"platform"]];
    }
}



-(void)writeJoints:(NSArray*)joints
{
    
    [self writeInt:(int)joints.count withSign:NO];
    for (NSDictionary * joint in joints)
    {
        [self writeJoint:joint];
    }
}

- (void) writeDocument:(NSDictionary*)doc
{
    NSDictionary* nodeGraph = [doc objectForKey:@"nodeGraph"];
    NSArray* joints = doc[@"joints"];
    
    [self cacheStringsForNode:nodeGraph];
    [self cacheStringsForSequences:doc];
    [self cacheStringsForJoints:joints];
    [self transformStringCache];
    
    [self writeHeader];
    [self writeStringCache];
    [self writeSequences:doc];
    [self writeNodeGraph:nodeGraph];
    [self writeJoints:joints];


    //Elias Gamma reader reads a full int off the end, reading outside the bounds by 3 bytes and setting off Guard Malloc detections. Pad file with 3 bytes.
    [self writeBool:NO];
    [self writeBool:NO];
    [self writeBool:NO];
}

#pragma mark - Document Properties


- (BOOL) isSprite:(NSString*) sprite inGeneratedSpriteSheet: (NSString*) sheet
{
    if (!sheet || [sheet isEqualToString:@""])
    {
        NSString* proposedSheetName = [sprite stringByDeletingLastPathComponent];
        if ([[serializedProjectSettings objectForKey:@"generatedSpriteSheets"] objectForKey:proposedSheetName])
        {
            return YES;
        }
    }
    return NO;
}


-(BOOL) hasPhysicsBodies:(NSDictionary*)doc
{
    NSMutableArray * nodes = [NSMutableArray array];
    
    [self getAllNodes:doc nodes:nodes];
    
    for (NSDictionary * node in nodes) {
        if(node[@"physicsBody"] != nil)
        {
            return YES;
        }
    }
    
    return NO;
}

-(BOOL) hasPhysicsNode:(NSDictionary*)doc
{
    NSMutableArray * nodes = [NSMutableArray array];
    
    [self getAllNodes:doc nodes:nodes];
    
    for (NSDictionary * node in nodes) {
        if([node[@"baseClass"] isEqualToString:@"CCPhysicsNode"])
        {
            return YES;
        }
    }
    
    return NO;
}




-(void)getAllNodes:(NSDictionary*)currentNode nodes:(NSMutableArray*)nodes
{
    [nodes addObject:currentNode];

    NSArray * children = currentNode[@"children"];
    
    for (NSDictionary * child in children) {
        [self getAllNodes:child nodes:nodes];
    }
}

#pragma mark -

@end
