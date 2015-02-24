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
#import "MigrationController.h"
#import "FileSystemTestCase.h"
#import "Errors.h"
#import "MigratorProtocol.h"
#import "MigrationControllerDelegate.h"


@interface MigrationController_Tests : FileSystemTestCase <MigrationControllerDelegate>

@property (nonatomic, strong) MigrationController *migrationController;
@property (nonatomic) BOOL migrationControllerDelegateResult;

@end


@implementation MigrationController_Tests

- (void)setUp
{
    [super setUp];

    self.migrationController = [[MigrationController alloc] init];
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
    id migratorMock1 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];
    id migratorMock2 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];

    _migrationController.migrators = @[migratorMock1, migratorMock2];

    [[[migratorMock1 expect] andReturnValue:@(NO)] isMigrationRequired];
    [[[migratorMock2 expect] andReturnValue:@(NO)] isMigrationRequired];

    NSError *error;
    XCTAssertTrue([_migrationController migrateWithError:&error]);
    XCTAssertNil(error);

    [migratorMock1 verify];
    [migratorMock2 verify];
};

- (void)testMigration
{
    self.migrationControllerDelegateResult = YES;

    id migratorMock1 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];
    id migratorMock2 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];

    _migrationController.migrators = @[migratorMock1, migratorMock2];
    _migrationController.delegate = self;

    [OCMStub([migratorMock1 isMigrationRequired]) andReturnValue:@(NO)];
    [OCMStub([migratorMock2 isMigrationRequired]) andReturnValue:@(YES)];
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

    id migratorMock1 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];
    id migratorMock2 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];

    _migrationController.migrators = @[migratorMock1, migratorMock2];
    _migrationController.delegate = self;

    [OCMStub([migratorMock1 isMigrationRequired]) andReturnValue:@(YES)];
    [OCMStub([migratorMock2 isMigrationRequired]) andReturnValue:@(YES)];
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

- (void)testDelegateCancellingMigration
{
    self.migrationControllerDelegateResult = NO;

    id migratorMock1 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];
    [OCMStub([migratorMock1 isMigrationRequired]) andReturnValue:@(YES)];
    [OCMStub([migratorMock1 htmlInfoText]) andReturn:@"1"];

    _migrationController.migrators = @[migratorMock1];
    _migrationController.delegate = self;

    NSError *error;
    XCTAssertFalse([_migrationController migrateWithError:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, SBCCBMigrationCancelledError);
}

#pragma mark - helpers

- (BOOL)migrateWithMigrationDetails:(NSString *)migrationDetails
{
    return _migrationControllerDelegateResult;
}

@end
