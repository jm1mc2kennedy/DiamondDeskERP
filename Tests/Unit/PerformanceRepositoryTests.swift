//
//  PerformanceRepositoryTests.swift
//  DiamondDeskERPTests
//
//  Created by GitHub Copilot on 1/2/2025.
//

import Testing
import CloudKit
import Foundation
@testable import DiamondDeskERP

@MainActor
struct PerformanceRepositoryTests {
    
    // MARK: - Mock Repository Implementations
    
    class MockVendorPerformanceRepository: VendorPerformanceRepositoryProtocol {
        var mockPerformances: [VendorPerformance] = []
        var shouldThrowError = false
        
        func fetchAll() async throws -> [VendorPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances
        }
        
        func fetchCurrentPeriod() async throws -> [VendorPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            let currentMonth = Calendar.current.component(.month, from: Date())
            let currentYear = Calendar.current.component(.year, from: Date())
            return mockPerformances.filter { 
                $0.reportingPeriod == .monthly &&
                Calendar.current.component(.month, from: $0.periodStartDate) == currentMonth &&
                Calendar.current.component(.year, from: $0.periodStartDate) == currentYear
            }
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
            return mockPerformances.filter { 
                $0.reportingPeriod == period &&
                Calendar.current.component(.year, from: $0.periodStartDate) == year
            }
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
    
    class MockCategoryPerformanceRepository: CategoryPerformanceRepositoryProtocol {
        var mockPerformances: [CategoryPerformance] = []
        var shouldThrowError = false
        
        func fetchAll() async throws -> [CategoryPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances
        }
        
        func fetchCurrentPeriod() async throws -> [CategoryPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            let currentMonth = Calendar.current.component(.month, from: Date())
            let currentYear = Calendar.current.component(.year, from: Date())
            return mockPerformances.filter { 
                $0.reportingPeriod == .monthly &&
                Calendar.current.component(.month, from: $0.periodStartDate) == currentMonth &&
                Calendar.current.component(.year, from: $0.periodStartDate) == currentYear
            }
        }
        
        func fetchByCategory(_ categoryId: String) async throws -> [CategoryPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances.filter { $0.categoryId == categoryId }
        }
        
        func fetchByStore(_ storeCode: String) async throws -> [CategoryPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances.filter { $0.storeCode == storeCode }
        }
        
        func fetchByPeriod(_ period: CategoryPerformance.ReportingPeriod, year: Int) async throws -> [CategoryPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances.filter { 
                $0.reportingPeriod == period &&
                Calendar.current.component(.year, from: $0.periodStartDate) == year
            }
        }
        
        func fetchTopPerformingCategories(limit: Int) async throws -> [CategoryPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return Array(mockPerformances.sorted { $0.performance.overallScore > $1.performance.overallScore }.prefix(limit))
        }
        
        func fetchUnderperformingCategories() async throws -> [CategoryPerformance] {
            if shouldThrowError { throw CKError(.networkFailure) }
            return mockPerformances.filter { 
                $0.performance.categoryGrade == .poor || $0.performance.categoryGrade == .failing 
            }
        }
        
        func save(_ performance: CategoryPerformance) async throws -> CategoryPerformance {
            if shouldThrowError { throw CKError(.quotaExceeded) }
            mockPerformances.removeAll { $0.id == performance.id }
            mockPerformances.append(performance)
            return performance
        }
        
        func delete(_ performance: CategoryPerformance) async throws {
            if shouldThrowError { throw CKError(.networkFailure) }
            mockPerformances.removeAll { $0.id == performance.id }
        }
    }
    
    class MockSalesTargetRepository: SalesTargetRepositoryProtocol {
        var mockTargets: [SalesTarget] = []
        var shouldThrowError = false
        
        func fetchAll() async throws -> [SalesTarget] {
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
            return mockTargets.filter { 
                $0.period == period &&
                Calendar.current.component(.year, from: $0.startDate) == year
            }
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
            if shouldThrowError { throw CKError(.quotaExceeded) }
            var updatedTarget = target
            updatedTarget.achievements.currentValue = currentValue
            updatedTarget.achievements.lastUpdated = Date()
            
            // Calculate achievement percentage and status
            let achievementPercentage = (currentValue / target.targetValue) * 100
            updatedTarget.achievements.achievementPercentage = achievementPercentage
            
            let remainingDays = Calendar.current.dateComponents([.day], from: Date(), to: target.endDate).day ?? 0
            let totalDays = Calendar.current.dateComponents([.day], from: target.startDate, to: target.endDate).day ?? 1
            let elapsedPercentage = Double(totalDays - remainingDays) / Double(totalDays) * 100
            
            if achievementPercentage >= 100 {
                updatedTarget.achievements.achievementStatus = .achieved
            } else if achievementPercentage >= elapsedPercentage {
                updatedTarget.achievements.achievementStatus = .onTrack
            } else if achievementPercentage >= elapsedPercentage * 0.8 {
                updatedTarget.achievements.achievementStatus = .atRisk
            } else {
                updatedTarget.achievements.achievementStatus = .behindTarget
            }
            
            mockTargets.removeAll { $0.id == target.id }
            mockTargets.append(updatedTarget)
            return updatedTarget
        }
    }
    
    // MARK: - VendorPerformance Repository Tests
    
    @Test("VendorPerformanceRepository fetchAll returns all performances")
    func testVendorPerformanceRepositoryFetchAll() async throws {
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
        
        let performances = try await mockRepository.fetchAll()
        
        #expect(performances.count == 1)
        #expect(performances.first?.vendorName == "Test Vendor")
        #expect(performances.first?.percentageScore == 85.0)
    }
    
    @Test("VendorPerformanceRepository fetchTopPerformers returns sorted performers")
    func testVendorPerformanceRepositoryFetchTopPerformers() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        
        let performance1 = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-1"),
            vendorId: "vendor-1",
            vendorName: "Average Vendor",
            storeCode: "001",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 70.0,
            maxPossibleScore: 100.0,
            percentageScore: 70.0,
            grade: .average,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let performance2 = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-2"),
            vendorId: "vendor-2",
            vendorName: "Excellent Vendor",
            storeCode: "002",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 95.0,
            maxPossibleScore: 100.0,
            percentageScore: 95.0,
            grade: .excellent,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockPerformances = [performance1, performance2]
        
        let topPerformers = try await mockRepository.fetchTopPerformers(limit: 5)
        
        #expect(topPerformers.count == 2)
        #expect(topPerformers.first?.vendorName == "Excellent Vendor")
        #expect(topPerformers.first?.percentageScore == 95.0)
        #expect(topPerformers.last?.vendorName == "Average Vendor")
    }
    
    @Test("VendorPerformanceRepository fetchUnderperformers returns poor performers")
    func testVendorPerformanceRepositoryFetchUnderperformers() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        
        let goodPerformance = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-good"),
            vendorId: "vendor-good",
            vendorName: "Good Vendor",
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
        
        let poorPerformance = VendorPerformance(
            id: CKRecord.ID(recordName: "vendor-perf-poor"),
            vendorId: "vendor-poor",
            vendorName: "Poor Vendor",
            storeCode: "002",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            totalScore: 40.0,
            maxPossibleScore: 100.0,
            percentageScore: 40.0,
            grade: .poor,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockPerformances = [goodPerformance, poorPerformance]
        
        let underperformers = try await mockRepository.fetchUnderperformers()
        
        #expect(underperformers.count == 1)
        #expect(underperformers.first?.vendorName == "Poor Vendor")
        #expect(underperformers.first?.grade == .poor)
    }
    
    // MARK: - CategoryPerformance Repository Tests
    
    @Test("CategoryPerformanceRepository fetchByCategory returns category performances")
    func testCategoryPerformanceRepositoryFetchByCategory() async throws {
        let mockRepository = MockCategoryPerformanceRepository()
        
        let performance1 = CategoryPerformance(
            id: CKRecord.ID(recordName: "cat-perf-1"),
            categoryId: "cat-electronics",
            categoryName: "Electronics",
            storeCode: "001",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            metrics: CategoryPerformance.CategoryMetrics(
                sales: CategoryPerformance.SalesMetrics(
                    totalRevenue: 10000.0,
                    totalUnits: 50,
                    averageOrderValue: 200.0,
                    returnRate: 0.05
                ),
                inventory: CategoryPerformance.InventoryMetrics(
                    turnoverRate: 4.5,
                    stockoutDays: 2,
                    avgStockLevel: 100.0,
                    shrinkageRate: 0.02
                ),
                customer: CategoryPerformance.CustomerMetrics(
                    satisfactionScore: 4.2,
                    complaintCount: 1,
                    repeatPurchaseRate: 0.65
                )
            ),
            performance: CategoryPerformance.PerformanceAnalysis(
                overallScore: 82.0,
                categoryGrade: .good,
                trendsVsPreviousPeriod: 5.2,
                strengths: ["High turnover"],
                weaknesses: ["Low satisfaction"],
                recommendations: ["Improve service"]
            ),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let performance2 = CategoryPerformance(
            id: CKRecord.ID(recordName: "cat-perf-2"),
            categoryId: "cat-clothing",
            categoryName: "Clothing",
            storeCode: "001",
            reportingPeriod: .monthly,
            periodStartDate: Date(),
            periodEndDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            metrics: CategoryPerformance.CategoryMetrics(
                sales: CategoryPerformance.SalesMetrics(
                    totalRevenue: 8000.0,
                    totalUnits: 80,
                    averageOrderValue: 100.0,
                    returnRate: 0.08
                ),
                inventory: CategoryPerformance.InventoryMetrics(
                    turnoverRate: 3.2,
                    stockoutDays: 5,
                    avgStockLevel: 150.0,
                    shrinkageRate: 0.03
                ),
                customer: CategoryPerformance.CustomerMetrics(
                    satisfactionScore: 3.8,
                    complaintCount: 3,
                    repeatPurchaseRate: 0.45
                )
            ),
            performance: CategoryPerformance.PerformanceAnalysis(
                overallScore: 68.0,
                categoryGrade: .average,
                trendsVsPreviousPeriod: -2.1,
                strengths: ["Good variety"],
                weaknesses: ["High returns"],
                recommendations: ["Improve quality"]
            ),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockPerformances = [performance1, performance2]
        
        let electronicsPerformances = try await mockRepository.fetchByCategory("cat-electronics")
        
        #expect(electronicsPerformances.count == 1)
        #expect(electronicsPerformances.first?.categoryName == "Electronics")
        #expect(electronicsPerformances.first?.performance.overallScore == 82.0)
    }
    
    // MARK: - SalesTarget Repository Tests
    
    @Test("SalesTargetRepository fetchActive returns only active targets")
    func testSalesTargetRepositoryFetchActive() async throws {
        let mockRepository = MockSalesTargetRepository()
        
        let activeTarget = SalesTarget(
            id: CKRecord.ID(recordName: "target-active"),
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
        
        let inactiveTarget = SalesTarget(
            id: CKRecord.ID(recordName: "target-inactive"),
            targetName: "Old Target",
            targetType: .revenue,
            targetValue: 30000.0,
            period: .monthly,
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            status: .completed,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 32000.0,
                achievementPercentage: 106.7,
                achievementStatus: .achieved,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockTargets = [activeTarget, inactiveTarget]
        
        let activeTargets = try await mockRepository.fetchActive()
        
        #expect(activeTargets.count == 1)
        #expect(activeTargets.first?.targetName == "Q1 Sales Target")
        #expect(activeTargets.first?.status == .active)
    }
    
    @Test("SalesTargetRepository updateAchievement calculates correct status")
    func testSalesTargetRepositoryUpdateAchievement() async throws {
        let mockRepository = MockSalesTargetRepository()
        
        let target = SalesTarget(
            id: CKRecord.ID(recordName: "target-1"),
            targetName: "Monthly Sales",
            targetType: .revenue,
            targetValue: 10000.0,
            period: .monthly,
            startDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            status: .active,
            storeCode: "001",
            employeeRef: nil,
            achievements: SalesTarget.AchievementTracking(
                currentValue: 3000.0,
                achievementPercentage: 30.0,
                achievementStatus: .behindTarget,
                lastUpdated: Date()
            ),
            createdByRef: CKRecord.Reference(recordID: CKRecord.ID(recordName: "user-1"), action: .none),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository.mockTargets = [target]
        
        let updatedTarget = try await mockRepository.updateAchievement(target, currentValue: 5500.0)
        
        #expect(updatedTarget.achievements.currentValue == 5500.0)
        #expect(updatedTarget.achievements.achievementPercentage == 55.0)
        #expect(updatedTarget.achievements.achievementStatus == .onTrack)
        #expect(mockRepository.mockTargets.first?.achievements.currentValue == 5500.0)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("VendorPerformanceRepository handles network errors")
    func testVendorPerformanceRepositoryNetworkError() async throws {
        let mockRepository = MockVendorPerformanceRepository()
        mockRepository.shouldThrowError = true
        
        do {
            _ = try await mockRepository.fetchAll()
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is CKError)
        }
    }
    
    @Test("SalesTargetRepository handles save errors")
    func testSalesTargetRepositorySaveError() async throws {
        let mockRepository = MockSalesTargetRepository()
        mockRepository.shouldThrowError = true
        
        let target = SalesTarget(
            id: CKRecord.ID(recordName: "target-error"),
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
        
        do {
            _ = try await mockRepository.save(target)
            #expect(Bool(false), "Expected error to be thrown")
        } catch {
            #expect(error is CKError)
        }
    }
}
