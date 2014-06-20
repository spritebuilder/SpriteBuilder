//
//  PackageExporter_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 16.06.14.
//
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ProjectSettings.h"
#import "SBErrors.h"
#import "NSString+Packages.h"
#import "RMPackage.h"
#import "PackageExporter.h"

@interface PackageExporter_Tests : XCTestCase

@end

@implementation PackageExporter_Tests
{
    PackageExporter *_packageExporter;
    id _fileManagerMock;
}

- (void)setUp
{
    [super setUp];

    _packageExporter = [[PackageExporter alloc] init];

    _fileManagerMock = [OCMockObject niceMockForClass:[NSFileManager class]];
    _packageExporter.fileManager = _fileManagerMock;
}

- (void)testPackageExportWithExistingExportFolderAtDestination
{
    id mockFileManager = [OCMockObject mockForClass:[NSFileManager class]];
    _packageExporter.fileManager = mockFileManager;

    [[[mockFileManager expect] andReturnValue:@(YES)] fileExistsAtPath:OCMOCK_ANY];

    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = [@"/baa/foo" stringByAppendingPackageSuffix];

    NSError *error;
    XCTAssertFalse([_packageExporter exportPackage:package toPath:@"/foo" error:&error]);
    XCTAssertNotNil(error, @"Error object should be set");
    XCTAssertEqual(error.code, SBPackageAlreadyExistsAtPathError);

    [mockFileManager verify];
}

- (void)testPackageExport
{
    id mockFileManager = [OCMockObject mockForClass:[NSFileManager class]];
    _packageExporter.fileManager = mockFileManager;

    NSString *toPath = @"/foo";
    RMPackage *package = [[RMPackage alloc] init];
    package.dirPath = @"/baa/superpackage.sbpack";
    NSString *expectedCopyToPath = [@"/foo/superpackage" stringByAppendingPackageSuffix];

    [[[mockFileManager expect] andReturnValue:@(NO)] fileExistsAtPath:expectedCopyToPath];
    [[[mockFileManager expect] andReturnValue:@(YES)] copyItemAtPath:package.dirPath toPath:expectedCopyToPath error:[OCMArg anyObjectRef]];

    NSError *error;
    XCTAssertTrue([_packageExporter exportPackage:package toPath:toPath error:&error]);
    XCTAssertNil(error);
}

- (void)testPackageExportWithWrongInput
{
    id wrongPackage = @"I'm a package for sure!";
    NSError *error;

    XCTAssertFalse([_packageExporter exportPackage:wrongPackage toPath:@"/foo" error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBPackageExportInvalidPackageError);
}

- (void)testPackageWithoutPath
{
    RMPackage *package = [[RMPackage alloc] init];
    NSError *error;

    XCTAssertFalse([_packageExporter exportPackage:package toPath:@"/foo" error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBPackageExportInvalidPackageError);
}

@end
