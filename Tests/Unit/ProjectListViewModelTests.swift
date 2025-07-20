import XCTest
@testable import DiamondDeskERP

@MainActor
class ProjectListViewModelTests: XCTestCase {
    // Mock success service
    class MockSuccessService: ProjectService {
        override init() { super.init() }
        override func fetchProjects() async throws -> [Project] {
            return [Project(name: "Project1", description: "Test project", startDate: Date(), endDate: nil, status: .active)]
        }
    }

    // Mock failure service
    class MockFailService: ProjectService {
        override init() { super.init() }
        override func fetchProjects() async throws -> [Project] {
            throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Load failed"])
        }
    }

    func testLoadProjectsSuccess() async {
        let viewModel = ProjectListViewModel(service: MockSuccessService())
        XCTAssertFalse(viewModel.isLoading)
        let task = Task { await viewModel.loadProjects() }
        XCTAssertTrue(viewModel.isLoading)
        await task.value
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.projects.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadProjectsFailure() async {
        let viewModel = ProjectListViewModel(service: MockFailService())
        await viewModel.loadProjects()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.projects.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Load failed")
    }
}
