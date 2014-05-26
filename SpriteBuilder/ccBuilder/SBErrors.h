// SpriteBuilder error domain
extern NSString *const SBErrorDomain;

// === Error codes ===

// GUI / DragnDrop
extern NSInteger const SBNodeDoesNotSupportChildrenError;
extern NSInteger const SBChildRequiresSpecificParentError;
extern NSInteger const SBParentDoesNotPermitSpecificChildrenError;

// Update Cocos2d
extern NSInteger const SBCocos2dUpdateTemplateZipFileDoesNotExistError;
extern NSInteger const SBCocos2dUpdateUnzipTemplateFailedError;
extern NSInteger const SBCocos2dUpdateUnzipTaskError;

// Resource path / Packages
extern NSInteger const SBDuplicateResourcePathError;
extern NSInteger const SBResourcePathNotInProject;
extern NSInteger const SBImportingPackagesError;
