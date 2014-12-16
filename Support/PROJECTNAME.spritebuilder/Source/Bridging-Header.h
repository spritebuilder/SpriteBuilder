#import "cocos2d.h"
#import "cocos2d-ui.h"

// Imported explicitly and with relative path.
// Class would otherwise be available but not autocompleting/syntax-highlighting.
// Perhaps an Xcode bug?
#import "libs/cocos2d-iphone/cocos2d/Support/CCColor.h"
#import "libs/cocos2d-iphone/cocos2d-ui/CCBReader/CCBReader.h"
#import "libs/cocos2d-iphone/cocos2d-ui/CCControl.h"
#import "libs/cocos2d-iphone/cocos2d-ui/CCButton.h"
#import "libs/cocos2d-iphone/cocos2d-ui/CCSlider.h"
#import "libs/cocos2d-iphone/cocos2d-ui/CCTextField.h"
#import "libs/cocos2d-iphone/external/ObjectAL/ObjectAL/ObjectAL/ObjectAL.h"
#import "libs/cocos2d-iphone/external/ObjectAL/ObjectAL/ObjectAL/AudioTrack/OALAudioTrack.h"
#import "libs/cocos2d-iphone/external/ObjectAL/ObjectAL/ObjectAL/AudioTrack/OALAudioTracks.h"
#import "libs/cocos2d-iphone/external/ObjectAL/ObjectAL/ObjectAL/Session/OALAudioSession.h"
