#if canImport(XCTest)
//
//  PerformanceViewModelTests.swift
//  DiamondDeskERPTests
//
//  Created by GitHub Copilot on 1/2/2025.
//

import CloudKit
import Combine

@MainActor
struct PerformanceViewModelTests {
    
    // MARK: - Mock Repository Implementations
    
    class MockVendorPerformanceRepository: VendorPerformanceRepositoryProtocol {
        var mockPerformances: [VendorPerformance] = []
        var shouldThrowError = false
        var fetchAllCallCount = 0
        var saveCallCount = 0
        
        func fetchAll() async throws -> [VendorPerformance] {
            fetchAllCallCount += 1
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances
        }
        
        func fetchCurrentPeriod() async throws -> [VendorPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances.filter { $0.reportingPeriod == .monthly }
        }
        
        func fetchByVendor(_ vendorId: String) async throws -> [VendorPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances.filter { $0.vendorId == vendorId }
        }
        
        func fetchByStore(_ storeCode: String) async throws -> [VendorPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances.filter { $0.storeCode == storeCode }
        }
        
        func fetchByPeriod(_ period: VendorPerformance.ReportingPeriod, year: Int) async throws -> [VendorPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances.filter { $0.reportingPeriod == period }
        }
        
        func fetchTopPerformers(limit: Int) async throws -> [VendorPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return Array(mockPerformances.sorted { $0.percentageScore > $1.percentageScore }.prefix(limit))
        }
        
        func fetchUnderperformers() async throws -> [VendorPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances.filter { $0.grade == .poor || $0.grade == .failing }
        }
        
        func save(_ performance: VendorPerformance) async throws -> VendorPerformance {
            saveCallCount += 1
            if shouldThrowError { throw CKError(.quotaExceeded) }
            mockPerformances.removeAll { $0.id == performance.id }
            mockPerformances.append(performance)
            return performance
        }
        
        func delete(_ performance: VendorPerformance) async throws {
            if shouldThrowError { throw CKError(.networkFailure) }
            mockPerformances.removeAll { $0.id == performance.id }
        }
    }
    
    class MockSalesTargetRepository: SalesTargetRepositoryProtocol {
        var mockTargets: [SalesTarget] = []
        var shouldThrowError = false
        var fetchAllCallCount = 0
        var updateAchievementCallCount = 0
        
        func fetchAll() async throws -> [SalesTarget] {
            fetchAllCallCount += 1
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockTargets
        }
        
        func fetchActive() async throws -> [SalesTarget] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockTargets.filter { $0.status.isActive }
        }
        
        func fetchCurrentTargets() async throws -> [SalesTarget] {
            if shouldThrowError { throw CKError(.networkFailure) }
            let now = Date()
            return mockTargets.filter { $0.startDate <= now && $0.endDate >= now }
        }
        
        func fetchOverdueTargets() async throws -> [SalesTarget] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockTargets.filter { $0.isOverdue }
        }
        
        func fetchByStore(_ storeCode: String) async throws -> [SalesTarget] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockTargets.filter { $0.storeCode == storeCode }
        }
        
        func fetchByEmployee(_ employee: CKRecord.Reference) async throws -> [SalesTarget] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockTargets.filter { $0.employeeRef?.recordID == employee.recordID }
        }
        
        func fetchByPeriod(_ period: SalesTarget.TargetPeriod, year: Int) async throws -> [SalesTarget] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockTargets.filter { $0.period == period }
        }
        
        func save(_ target: SalesTarget) async throws -> SalesTarget {
            if shouldThrowError { throw CKError(.quotaExceeded) }
            mockTargets.removeAll { $0.id == target.id }
            mockTargets.append(target)
            return target
        }
        
        func delete(_ target: SalesTarget) async throws {
            if shouldThrowError { throw CKError(.networkFailure) }
            mockTargets.removeAll { $0.id == target.id }
        }
        
        func updateAchievement(_ target: SalesTarget, currentValue: Double) async throws -> SalesTarget {
            updateAchievementCallCount += 1
            if shouldThrowError { throw CKError(.quotaExceeded) }
            var updatedTarget = target
            updatedTarget.achievements.currentValue = currentValue
            updatedTarget.achievements.achievementPercentage = (currentValue / target.targetValue) * 100
            updatedTarget.achievements.lastUpdated = Date()
            mockTargets.removeAll { $0.id == target.id }
            mockTargets.append(updatedTarget)
            return updatedTarget
        }
    }
    
    // MARK: - VendorPerformanceViewModel Tests
    
    @Test("VendorPerformanceViewModel initializes with empty state")
    func testVendorPerformanceViewModelInitialization() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        let viewModel = VendorPerformanceViewModel(repository: mockRepository)
        
        #expect(viewModel.performances.isEmpty)
        #expect(viewModel.selectedPerformance == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.searchText.isEmpty)
    }
    
    @Test("VendorPerformanceViewModel loads performances successfully")
    func testVendorPerformanceViewModelLoadPerformances() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        
        let performance = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-1"),
            vendorId: "vendor-123",
            vendorName: "Test Vendor",
            storeCode: "001",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 85.0,
            maxPossibleScore: 100.0,
            percentageScore: 85.0,
            grade: .good,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockPerformances = [performance]
        let viewModel = VendorPerformanceViewModel(repository: mockRepository)
        
        viewModel.loadPerformances()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(mockRepository.fetchAllCallCount == 1)
        #expect(viewModel.performances.count == 1)
        #expect(viewModel.performances.first?.vendorName == "Test Vendor")
        #expect(viewModel.isLoading == false)
    }
    
    @Test("VendorPerformanceViewModel filters performances by search text")
    func testVendorPerformanceViewModelFiltering() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        
        let performance1 = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-1"),
            vendorId: "vendor-123",
            vendorName: "ABC Supplies",
            storeCode: "001",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 85.0,
            maxPossibleScore: 100.0,
            percentageScore: 85.0,
            grade: .good,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let performance2 = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-2"),
            vendorId: "vendor-456",
            vendorName: "XYZ Corp",
            storeCode: "002",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 92.0,
            maxPossibleScore: 100.0,
            percentageScore: 92.0,
            grade: .excellent,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let viewModel = VendorPerformanceViewModel(repository: mockRepository)
        viewModel.performances = [performance1, performance2]
        
        // Test search filtering by vendor name
        viewModel.searchText = "ABC"
        let filteredByName = viewModel.filteredPerformances
        #expect(filteredByName.count == 1)
        #expect(filteredByName.first?.vendorName == "ABC Supplies")
        
        // Test search filtering by store code
        viewModel.searchText = "002"
        let filteredByStore = viewModel.filteredPerformances
        #expect(filteredByStore.count == 1)
        #expect(filteredByStore.first?.storeCode == "002")
        
        // Test vendor filtering
        viewModel.searchText = ""
        viewModel.selectedVendor = "vendor-456"
        let filteredByVendor = viewModel.filteredPerformances
        #expect(filteredByVendor.count == 1)
        #expect(filteredByVendor.first?.vendorId == "vendor-456")
    }
    
    @Test("VendorPerformanceViewModel calculates average score correctly")
    func testVendorPerformanceViewModelAverageScore() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        
        let performance1 = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-1"),
            vendorId: "vendor-1",
            vendorName: "Vendor 1",
            storeCode: "001",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 80.0,
            maxPossibleScore: 100.0,
            percentageScore: 80.0,
            grade: .good,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let performance2 = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-2"),
            vendorId: "vendor-2",
            vendorName: "Vendor 2",
            storeCode: "002",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 90.0,
            maxPossibleScore: 100.0,
            percentageScore: 90.0,
            grade: .excellent,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let viewModel = VendorPerformanceViewModel(repository: mockRepository)
        viewModel.performances = [performance1, performance2]
        
        let averageScore = viewModel.averageScore
        #expect(averageScore == 85.0) // (80 + 90) / 2 = 85
    }
    
    @Test("VendorPerformanceViewModel groups performances by vendor")
    func testVendorPerformanceViewModelGrouping() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        
        let performance1 = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-1"),
            vendorId: "vendor-1",
            vendorName: "Vendor 1",
            storeCode: "001",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 80.0,
            maxPossibleScore: 100.0,
            percentageScore: 80.0,
            grade: .good,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let performance2 = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-2"),
            vendorId: "vendor-1",
            vendorName: "Vendor 1",
            storeCode: "002",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 85.0,
            maxPossibleScore: 100.0,
            percentageScore: 85.0,
            grade: .good,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let viewModel = VendorPerformanceViewModel(repository: mockRepository)
        viewModel.performances = [performance1, performance2]
        
        let performancesByVendor = viewModel.performancesByVendor
        
        #expect(performancesByVendor.keys.count == 1)
        #expect(performancesByVendor["vendor-1"]?.count == 2)
    }
    
    @Test("VendorPerformanceViewModel saves performance successfully")
    func testVendorPerformanceViewModelSavePerformance() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        
        let performance = VendorPerformance(
            id: CKRecord.ID(recordName: "new-vendor-perf"),
            vendorId: "vendor-new",
            vendorName: "New Vendor",
            storeCode: "001",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 75.0,
            maxPossibleScore: 100.0,
            percentageScore: 75.0,
            grade: .average,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let viewModel = VendorPerformanceViewModel(repository: mockRepository)
        
        viewModel.savePerformance(performance)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(mockRepository.saveCallCount == 1)
        #expect(viewModel.performances.count == 1)
        #expect(viewModel.performances.first?.vendorName == "New Vendor")
    }
    
    @Test("VendorPerformanceViewModel handles loading errors")
    func testVendorPerformanceViewModelLoadingError() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        mockRepository.shouldThrowError = true
        
        let viewModel = VendorPerformanceViewModel(repository: mockRepository)
        
        viewModel.loadPerformances()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.performances.isEmpty)
    }
    
    // MARK: - SalesTargetViewModel Tests
    
    @Test("SalesTargetViewModel initializes with empty state")
    func testSalesTargetViewModelInitialization() async throws {
        let mockRepository = MockSalesTargetRepository()
        let viewModel = SalesTargetViewModel(repository: mockRepository)
        
        #expect(viewModel.targets.isEmpty)
        #expect(viewModel.selectedTarget == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.searchText.isEmpty)
    }
    
    @Test("SalesTargetViewModel loads targets successfully")
    func testSalesTargetViewModelLoadTargets() async throws {
        let mockRepository = MockSalesTargetRepository()
        
        let target = SalesTarget(
            id: CKRecord.ID(recordName: "target-1"),
            targetName: "Q1 Sales Target",
            targetType: .revenue,
            targetValue: 50000.0,
            period: .quarterly,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
            status: .active,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 25000.0,
                achievementPercentage: 50.0,
                achievementStatus: .onTrack,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockTargets = [target]
        let viewModel = SalesTargetViewModel(repository: mockRepository)
        
        viewModel.loadTargets()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(mockRepository.fetchAllCallCount == 1)
        #expect(viewModel.targets.count == 1)
        #expect(viewModel.targets.first?.targetName == "Q1 Sales Target")
        #expect(viewModel.isLoading == false)
    }
    
    @Test("SalesTargetViewModel filters targets by status")
    func testSalesTargetViewModelFilterByStatus() async throws {
        let mockRepository = MockSalesTargetRepository()
        
        let activeTarget = SalesTarget(
            id: CKRecord.ID(recordName: "active-target"),
            targetName: "Active Target",
            targetType: .revenue,
            targetValue: 30000.0,
            period: .monthly,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            status: .active,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 15000.0,
                achievementPercentage: 50.0,
                achievementStatus: .onTrack,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let completedTarget = SalesTarget(
            id: CKRecord.ID(recordName: "completed-target"),
            targetName: "Completed Target",
            targetType: .revenue,
            targetValue: 25000.0,
            period: .monthly,
            startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            endDate: Date(),
            status: .completed,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 27000.0,
                achievementPercentage: 108.0,
                achievementStatus: .achieved,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let viewModel = SalesTargetViewModel(repository: mockRepository)
        viewModel.targets = [activeTarget, completedTarget]
        
        // Test status filtering
        viewModel.selectedStatus = .active
        let filteredTargets = viewModel.filteredTargets
        
        #expect(filteredTargets.count == 1)
        #expect(filteredTargets.first?.status == .active)
        #expect(filteredTargets.first?.targetName == "Active Target")
    }
    
    @Test("SalesTargetViewModel calculates achievement rate correctly")
    func testSalesTargetViewModelAchievementRate() async throws {
        let mockRepository = MockSalesTargetRepository()
        
        let achievedTarget = SalesTarget(
            id: CKRecord.ID(recordName: "achieved-target"),
            targetName: "Achieved Target",
            targetType: .revenue,
            targetValue: 20000.0,
            period: .monthly,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            status: .active,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 22000.0,
                achievementPercentage: 110.0,
                achievementStatus: .achieved,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let onTrackTarget = SalesTarget(
            id: CKRecord.ID(recordName: "on-track-target"),
            targetName: "On Track Target",
            targetType: .revenue,
            targetValue: 30000.0,
            period: .monthly,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            status: .active,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 15000.0,
                achievementPercentage: 50.0,
                achievementStatus: .onTrack,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let viewModel = SalesTargetViewModel(repository: mockRepository)
        viewModel.targets = [achievedTarget, onTrackTarget]
        
        let achievementRate = viewModel.achievementRate
        #expect(achievementRate == 50.0) // 1 out of 2 achieved (>= 100%) = 50%
    }
    
    @Test("SalesTargetViewModel identifies on-track targets")
    func testSalesTargetViewModelOnTrackTargets() async throws {
        let mockRepository = MockSalesTargetRepository()
        
        let onTrackTarget = SalesTarget(
            id: CKRecord.ID(recordName: "on-track-target"),
            targetName: "On Track Target",
            targetType: .revenue,
            targetValue: 30000.0,
            period: .monthly,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            status: .active,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 15000.0,
                achievementPercentage: 50.0,
                achievementStatus: .onTrack,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let atRiskTarget = SalesTarget(
            id: CKRecord.ID(recordName: "at-risk-target"),
            targetName: "At Risk Target",
            targetType: .revenue,
            targetValue: 25000.0,
            period: .monthly,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            status: .active,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 8000.0,
                achievementPercentage: 32.0,
                achievementStatus: .atRisk,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let viewModel = SalesTargetViewModel(repository: mockRepository)
        viewModel.targets = [onTrackTarget, atRiskTarget]
        
        let onTrackTargets = viewModel.onTrackTargets
        let atRiskTargets = viewModel.atRiskTargets
        
        #expect(onTrackTargets.count == 1)
        #expect(onTrackTargets.first?.targetName == "On Track Target")
        
        #expect(atRiskTargets.count == 1)
        #expect(atRiskTargets.first?.targetName == "At Risk Target")
    }
    
    @Test("SalesTargetViewModel updates target achievement")
    func testSalesTargetViewModelUpdateAchievement() async throws {
        let mockRepository = MockSalesTargetRepository()
        
        let target = SalesTarget(
            id: CKRecord.ID(recordName: "target-1"),
            targetName: "Monthly Sales",
            targetType: .revenue,
            targetValue: 20000.0,
            period: .monthly,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            status: .active,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 10000.0,
                achievementPercentage: 50.0,
                achievementStatus: .onTrack,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockTargets = [target]
        let viewModel = SalesTargetViewModel(repository: mockRepository)
        viewModel.targets = [target]
        
        viewModel.updateTargetAchievement(target, currentValue: 15000.0)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(mockRepository.updateAchievementCallCount == 1)
        #expect(viewModel.targets.first?.achievements.currentValue == 15000.0)
        #expect(viewModel.targets.first?.achievements.achievementPercentage == 75.0)
    }
    
    @Test("SalesTargetViewModel handles save errors")
    func testSalesTargetViewModelSaveError() async throws {
        let mockRepository = MockSalesTargetRepository()
        mockRepository.shouldThrowError = true
        
        let target = SalesTarget(
            id: CKRecord.ID(recordName: "error-target"),
            targetName: "Error Target",
            targetType: .revenue,
            targetValue: 10000.0,
            period: .monthly,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            status: .active,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 0.0,
                achievementPercentage: 0.0,
                achievementStatus: .behindTarget,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let viewModel = SalesTargetViewModel(repository: mockRepository)
        
        viewModel.createTarget(target)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(viewModel.error != nil)
        #expect(viewModel.targets.isEmpty)
    }
}
#endif
