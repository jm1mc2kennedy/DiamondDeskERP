import XCTest
@testable import DiamondDeskERP

@MainActor
class PerformanceTargetsViewModelTests: XCTestCase {
    // Mock service for successful operations
    class MockSuccessService: PerformanceTargetsService {
        override init() { super.init() }
        override func fetchTargets() async throws -> [PerformanceTarget] {
            return [PerformanceTarget(name: "Test Target", description: nil, metricType: .custom, targetValue: 42, unit: "units", period: .weekly, recurrence: .none)]
        }
        override func saveTarget(_ target: PerformanceTarget) async throws {
            // no-op
        }
        override func deleteTarget(_ target: PerformanceTarget) async throws {
            // no-op
        }
    }
    
    // Mock service for failing fetch
    class MockFailService: PerformanceTargetsService {
        override init() { super.init() }
        override func fetchTargets() async throws -> [PerformanceTarget] {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch error"])
        }
    }
    
    func testLoadTargetsSuccess() async {
        let viewModel = PerformanceTargetsViewModel(service: MockSuccessService())
        XCTAssertFalse(viewModel.isLoading)
        let task = Task { await viewModel.loadTargets() }
        XCTAssertTrue(viewModel.isLoading)
        await task.value
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.targets.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadTargetsFailure() async {
        let viewModel = PerformanceTargetsViewModel(service: MockFailService())
        await viewModel.loadTargets()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.targets.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Fetch error")
    }
}
