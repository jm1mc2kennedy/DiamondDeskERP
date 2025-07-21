#if canImport(XCTest)
import CloudKit
import XCTest

class SeederTests: XCTestCase {

    var seeder: Seeder!
    var mockDatabase: MockCKDatabase!

    override func setUp() {
        super.setUp()
        mockDatabase = MockCKDatabase()
        seeder = Seeder(database: mockDatabase)
    }

    override func tearDown() {
        seeder = nil
        mockDatabase = nil
        super.tearDown()
    }

    func testSeedStores() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Save records to database")
        mockDatabase.saveRecordClosure = { record in
            expectation.fulfill()
        }

        // When
        try await seeder.seedStores()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockDatabase.savedRecords.count, 3)
        XCTAssertEqual(mockDatabase.savedRecords.first?.recordType, "Store")
        XCTAssertEqual(mockDatabase.savedRecords.first?["name"] as? String, "Corporate Headquarters")
    }
}

class MockCKDatabase: CKDatabase {
    var savedRecords: [CKRecord] = []
    var saveRecordClosure: ((CKRecord) -> Void)?

    override func save(_ record: CKRecord) async throws -> CKRecord {
        savedRecords.append(record)
        saveRecordClosure?(record)
        return record
    }
}
#endif
