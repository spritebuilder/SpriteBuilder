//
//  ProjectMigrationController_Tests.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 13.02.15.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ProjectMigrationController.h"
#import "FileSystemTestCase.h"
#import "SBErrors.h"
#import "ProjectMigratorProtocol.h"
#import "ProjectMigrationControllerDelegate.h"


@interface ProjectMigrationController_Tests : FileSystemTestCase <ProjectMigrationControllerDelegate>

@property (nonatomic, strong) ProjectMigrationController *migrationController;
@property (nonatomic) BOOL migrationControllerDelegateResult;

@end


@implementation ProjectMigrationController_Tests

- (void)setUp
{
    [super setUp];

    self.migrationController = [[ProjectMigrationController alloc] init];
}

- (void)testMigrationWithoutMigrators
{
    _migrationController.migrators = @[];

    NSError *error;
    XCTAssertFalse([_migrationController migrateWithError:&error]);

    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBProjectMigrationError);
}

- (void)testMigrationWithNoMigrationNeeded
{
    id migratorMock1 = [OCMockObject niceMockForProtocol:@protocol(ProjectMigratorProtocol)];
    id migratorMock2 = [OCMockObject niceMockForProtocol:@protocol(ProjectMigratorProtocol)];

    _migrationController.migrators = @[migratorMock1, migratorMock2];

    [[[migratorMock1 expect] andReturnValue:@(NO)] migrationRequired];
    [[[migratorMock2 expect] andReturnValue:@(NO)] migrationRequired];

    NSError *error;
    XCTAssertTrue([_migrationController migrateWithError:&error]);
    XCTAssertNil(error);

    [migratorMock1 verify];
    [migratorMock2 verify];
};

- (void)testMigration
{
    self.migrationControllerDelegateResult = YES;

    id migratorMock1 = [OCMockObject niceMockForProtocol:@protocol(ProjectMigratorProtocol)];
    id migratorMock2 = [OCMockObject niceMockForProtocol:@protocol(ProjectMigratorProtocol)];

    _migrationController.migrators = @[migratorMock1, migratorMock2];
    _migrationController.delegate = self;

    [OCMStub([migratorMock1 migrationRequired]) andReturnValue:@(NO)];
    [OCMStub([migratorMock2 migrationRequired]) andReturnValue:@(YES)];
    [OCMStub([migratorMock2 htmlInfoText]) andReturn:@"2"];

    [[[migratorMock1 expect] andReturnValue:@(YES)] migrateWithError:[OCMArg anyObjectRef]];
    [[[migratorMock2 expect] andReturnValue:@(YES)] migrateWithError:[OCMArg anyObjectRef]];

    NSError *error;
    XCTAssertTrue([_migrationController migrateWithError:&error]);
    XCTAssertNil(error);

    [migratorMock1 verify];
    [migratorMock2 verify];
}

- (void)testMigrationWithErrors
{
    self.migrationControllerDelegateResult = YES;

    id migratorMock1 = [OCMockObject niceMockForProtocol:@protocol(ProjectMigratorProtocol)];
    id migratorMock2 = [OCMockObject niceMockForProtocol:@protocol(ProjectMigratorProtocol)];

    _migrationController.migrators = @[migratorMock1, migratorMock2];
    _migrationController.delegate = self;

    [OCMStub([migratorMock1 migrationRequired]) andReturnValue:@(YES)];
    [OCMStub([migratorMock2 migrationRequired]) andReturnValue:@(YES)];
    [OCMStub([migratorMock1 htmlInfoText]) andReturn:@"1"];
    [OCMStub([migratorMock2 htmlInfoText]) andReturn:@"2"];

    NSError *error;
    [[[migratorMock1 expect] andReturnValue:@(YES)] migrateWithError:[OCMArg anyObjectRef]];
    [[[migratorMock2 expect] andReturnValue:@(NO)] migrateWithError:[OCMArg setTo:[NSError errorWithDomain:@"foo" code:12345678 userInfo:nil]]];

    [[migratorMock1 expect] rollback];
    [[migratorMock2 expect] rollback];

    XCTAssertFalse([_migrationController migrateWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, 12345678);

    [migratorMock1 verify];
    [migratorMock2 verify];
};

#pragma mark - helpers

- (BOOL)migrateWithMigrationDetails:(NSString *)migrationDetails
{
    return _migrationControllerDelegateResult;
}

@end
