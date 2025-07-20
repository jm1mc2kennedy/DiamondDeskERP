import XCTest
@testable import DiamondDeskERP

@MainActor
class DirectoryViewModelTests: XCTestCase {
    var viewModel: DirectoryViewModel!

    override func setUpWithError() throws {
        viewModel = DirectoryViewModel()
    }

    override func tearDownWithError() throws {
        viewModel = nil
    }

    /// Test that loading employees updates state correctly on success
    func testLoadEmployeesUpdatesState() async throws {
        // Given initial state
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.employees.isEmpty)
        XCTAssertNil(viewModel.errorMessage)

        // When loading employees
        let loadTask = Task { await viewModel.loadEmployees() }

        // Immediately after calling, isLoading should be true
        XCTAssertTrue(viewModel.isLoading)

        // Await completion
        await loadTask.value

        // Then viewModel should not be loading and have empty employees (since no data)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.employees.count, 0)
        XCTAssertNil(viewModel.errorMessage)
    }

    /// Test that an error during loading sets errorMessage
    func testLoadEmployeesHandlesError() async throws {
        // Arrange: temporarily override service to throw error
        class FailingService: DirectoryService {
            override func fetchEmployees(criteria: DirectorySearchCriteria) async throws -> [Employee] {
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            }
        }
        // Exchange shared instance
        let originalService = DirectoryService.shared
        DirectoryService.shared = FailingService.shared

        defer { DirectoryService.shared = originalService }

        // When loading employees
        await viewModel.loadEmployees()

        // Then errorMessage is set and employees remain empty
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.employees.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
