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

@interface MigrationController_Tests : FileSystemTestCase

@property (nonatomic, strong) MigrationController *migrationController;

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
    id migratorMock1 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];
    id migratorMock2 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];

    _migrationController.migrators = @[migratorMock1, migratorMock2];

    [OCMStub([migratorMock1 isMigrationRequired]) andReturnValue:@(NO)];
    [OCMStub([migratorMock2 isMigrationRequired]) andReturnValue:@(YES)];

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
    id migratorMock1 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];
    id migratorMock2 = [OCMockObject niceMockForProtocol:@protocol(MigratorProtocol)];

    _migrationController.migrators = @[migratorMock1, migratorMock2];

    [OCMStub([migratorMock1 isMigrationRequired]) andReturnValue:@(YES)];
    [OCMStub([migratorMock2 isMigrationRequired]) andReturnValue:@(YES)];

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

@end
