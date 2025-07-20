import XCTest
@testable import DiamondDeskERP

class SequenceUniqueTests: XCTestCase {
    func testUniqueRemovesDuplicates() {
        let array = [1, 2, 2, 3, 1, 4]
        let unique = array.unique()
        XCTAssertEqual(unique, [1, 2, 3, 4])
    }

    func testUniqueEmptySequence() {
        let empty: [String] = []
        let unique = empty.unique()
        XCTAssertTrue(unique.isEmpty)
    }

    func testUniqueAllUnique() {
        let array = ["a", "b", "c"]
        let unique = array.unique()
        XCTAssertEqual(unique, ["a", "b", "c"])
    }
}
