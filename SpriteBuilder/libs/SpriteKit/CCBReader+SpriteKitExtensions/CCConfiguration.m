/*
 * SpriteBuilder: http://www.spritebuilder.org
 *
 * Copyright (c) 2010 Ricardo Quesada
 * Copyright (c) 2011 Zynga Inc.
 * Copyright (c) 2014 Apportable Inc.
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

#import "CCConfiguration.h"
#import "CCBSpriteKitCompatibility.h"

@implementation CCConfiguration

static CCConfiguration *sharedConfiguration = nil;

+(CCConfiguration*) sharedConfiguration
{
	if (sharedConfiguration == nil)
	{
		sharedConfiguration = [[self alloc] init];
	}
	
	return sharedConfiguration;
}

-(id) init
{
	self = [super init];
	if (self)
	{
		[self determineRunningDevice];
	}
	return self;
}

-(void) determineRunningDevice
{
	_runningDevice = CCDeviceUnknown;
	
#ifdef __CC_PLATFORM_IOS
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		_runningDevice = ([UIScreen mainScreen].scale == 2) ? CCDeviceiPadRetinaDisplay : CCDeviceiPad;
	}
	else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		// From http://stackoverflow.com/a/12535566
		BOOL isiPhone5 = CGSizeEqualToSize([UIScreen mainScreen].preferredMode.size, CGSizeMake(640, 1136));
		
		if ([UIScreen mainScreen].scale == 2)
		{
			_runningDevice = isiPhone5 ? CCDeviceiPhone5RetinaDisplay : CCDeviceiPhoneRetinaDisplay;
		}
		else
		{
			_runningDevice = isiPhone5 ? CCDeviceiPhone5 : CCDeviceiPhone;
		}
	}
	
#elif defined(__CC_PLATFORM_MAC)
	
	// XXX: Add here support for Mac Retina Display
	_runningDevice = CCDeviceMac;
	
#endif // __CC_PLATFORM_MAC
}

@end
