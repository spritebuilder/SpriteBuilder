#import "ResourceCommandProtocol.h"

#import "ResourceNewPackageCommand.h"
#import "ProjectSettings.h"
#import "PackageCreator.h"
#import "ResourceManager.h"
#import "RMPackage.h"

@implementation ResourceNewPackageCommand

- (void)execute
{
    NSAssert(_windowForModals != nil, @"windowForModals must no be nil, modal sheet can't be attached.");

    PackageCreator *packageCreator = [[PackageCreator alloc] init];
    packageCreator.projectSettings = _projectSettings;

    NSError *error;
    NSString *newPackageName = [packageCreator creatablePackageNameWithBaseName:@"Untitled Package"];
    NSString *fullPath = [packageCreator createPackageWithName:newPackageName error:&error];
    if (!fullPath)
    {
        [self showCannotCreatePackageWarningWithError:error];
        return;
    }

    [self selectAndMakePackageNameEditableWithNewPath:fullPath];
}

- (void)selectAndMakePackageNameEditableWithNewPath:(NSString *)newPackagePath
{
    RMDirectory *newPackage = [_resourceManager directoryForPath:newPackagePath];

    [_outlineView editColumn:0 row:[_outlineView rowForItem:newPackage] withEvent:nil select:YES];
}

- (void)showCannotCreatePackageWarningWithError:(NSError *)error
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Error"
                                     defaultButton:@"Ok"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", error.localizedDescription];

    [alert runModal];
}


#pragma mark - ResourceCommandContextMenuProtocol

+ (NSString *)nameForResources:(NSArray *)resources
{
    return @"New Package";
}

+ (BOOL)isValidForSelectedResources:(NSArray *)resources
{
    return YES;
}


@end