//
//  CCBSpriteKitMacros.h
//  SpriteKitReader-Experimental
//
//  Created by Steffen Itterheim on 09/01/14.
//  Copyright (c) 2014 Steffen Itterheim. All rights reserved.
//

#ifndef SpriteKitReader_Experimental_CCBSpriteKitMacros_h
#define SpriteKitReader_Experimental_CCBSpriteKitMacros_h


#ifdef DEBUG
#   define NOTIMPLEMENTED() NSLog((@"%@:%s is not implemented"), NSStringFromClass([self class]), __PRETTY_FUNCTION__)
#else
#   define NOTIMPLEMENTED(...)
#endif


#endif
