@class ProjectSettings;
@class CCBWarnings;
@class CCBPublisher;

typedef void (^PublisherFinishBlock)(CCBPublisher *publisher, CCBWarnings *warnings);

typedef enum {
    kCCBPublisherOSTypeHTML5 = 0,
    kCCBPublisherOSTypeIOS = 1,
    kCCBPublisherOSTypeAndroid = 2,
} CCBPublisherOSType;

enum {
    kCCBPublishFormatSound_ios_caf = 0,
    kCCBPublishFormatSound_ios_mp4 = 1,
} typedef kCCBPublishFormatSound_ios;

enum {
    kCCBPublishFormatSound_android_ogg = 0,
} typedef kCCBPublishFormatSound_android;
