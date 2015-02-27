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
extern NSInteger const SBCocos2dUpdateCopyFilesError;
extern NSInteger const SBCocos2dUpdateUserCancelledError;

// Resource path / Packages
extern NSInteger const SBDuplicatePackageError;
extern NSInteger const SBPackageNotInProjectError;
extern NSInteger const SBImportingPackagesError;
extern NSInteger const SBRemovePackagesError;
extern NSInteger const SBPackageExistsButNotInProjectError;
extern NSInteger const SBPackageExportInvalidPackageError;
extern NSInteger const SBPackageAlreadyExistsAtPathError;
extern NSInteger const SBRenamePackageGenericError;
extern NSInteger const SBPathWithoutPackageSuffix;
extern NSInteger const SBNoPackagePathsToImport;
extern NSInteger const SBPackageAlreayInProject;
extern NSInteger const SBEmptyPackageNameError;

// Migration in general
extern NSInteger const SBMigrationError;
extern NSInteger const SBMigrationCannotDowngradeError;

// CCB Reading and writing
extern NSInteger const SBCCBReadingError;
extern NSInteger const SBCCBReadingErrorInvalidFileType;
extern NSInteger const SBCCBReadingErrorVersionTooOld;
extern NSInteger const SBCCBReadingErrorVersionHigherThanSpritebuilderSupport;
extern NSInteger const SBCCBReadingErrorNoNodesFound;

extern NSInteger const SBCCBMigrationError;
extern NSInteger const SBCCBMigrationCancelledError;
extern NSInteger const SBCCBMigrationNoMigrationStepClassPrefixError;
extern NSInteger const SBCCBMigrationNoVersionFoundError;

// Package Settings reading, writing & migration
extern NSInteger const SBPackageSettingsMigrationNoRuleError;
extern NSInteger const SBPackageSettingsEmptyOrDoesNotExist;

// Project Migration
extern NSInteger const SBProjectMigrationError;

// File Commands
extern NSInteger const SBFileCommandBackupError;
extern NSInteger const SBFileCommandBackupAlreadyExecutedError;
extern NSInteger const SBFileCommandBackupAlreadyUndoneError;
extern NSInteger const SBFileCommandBackupCannotUndoNonExecutedCommandError;

