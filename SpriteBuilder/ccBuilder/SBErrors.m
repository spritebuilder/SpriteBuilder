// SpriteBuilder error domain
NSString *const SBErrorDomain = @"SBErrorDomain";

// === Error codes ===

// GUI / DragnDrop
NSInteger const SBNodeDoesNotSupportChildrenError = 1000;
NSInteger const SBChildRequiresSpecificParentError = 1001;
NSInteger const SBParentDoesNotPermitSpecificChildrenError = 1002;

// Update Cocos2d
NSInteger const SBCocos2dUpdateTemplateZipFileDoesNotExistError = 2000;