import Foundation
import CloudKit
import Combine

// MARK: - VendorPerformance Repository Protocol
protocol VendorPerformanceRepositoryProtocol {
    func fetchAll() async throws -> [VendorPerformance]
    func fetchByVendor(_ vendorId: String) async throws -> [VendorPerformance]
    func fetchByStore(_ storeCode: String) async throws -> [VendorPerformance]
    func fetchByPeriod(_ period: VendorPerformance.ReportingPeriod, year: Int) async throws -> [VendorPerformance]
    func fetchCurrentPeriod() async throws -> [VendorPerformance]
    func fetch(byId id: CKRecord.ID) async throws -> VendorPerformance?
    func save(_ performance: VendorPerformance) async throws -> VendorPerformance
    func delete(_ performance: VendorPerformance) async throws
    func fetchTopPerformers(limit: Int) async throws -> [VendorPerformance]
    func fetchUnderperformers() async throws -> [VendorPerformance]
}

// MARK: - CloudKit VendorPerformance Repository
class CloudKitVendorPerformanceRepository: VendorPerformanceRepositoryProtocol {
    private let database: CKDatabase
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchAll() async throws -> [VendorPerformance] {
        let query = CKQuery(recordType: "VendorPerformance", predicate: NSPredicate(format: "isActive == YES"))
        query.sortDescriptors = [NSSortDescriptor(key: "periodStart", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return VendorPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByVendor(_ vendorId: String) async throws -> [VendorPerformance] {
        let predicate = NSPredicate(format: "vendorId == %@ AND isActive == YES", vendorId)
        let query = CKQuery(recordType: "VendorPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "periodStart", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return VendorPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByStore(_ storeCode: String) async throws -> [VendorPerformance] {
        let predicate = NSPredicate(format: "storeCode == %@ AND isActive == YES", storeCode)
        let query = CKQuery(recordType: "VendorPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "overallScore", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return VendorPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByPeriod(_ period: VendorPerformance.ReportingPeriod, year: Int) async throws -> [VendorPerformance] {
        let startOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = Calendar.current.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        
        let predicate = NSPredicate(format: "reportingPeriod == %@ AND periodStart >= %@ AND periodStart < %@ AND isActive == YES",
                                  period.rawValue, startOfYear as NSDate, endOfYear as NSDate)
        let query = CKQuery(recordType: "VendorPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "overallScore", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return VendorPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchCurrentPeriod() async throws -> [VendorPerformance] {
        let now = Date()
        let predicate = NSPredicate(format: "periodStart <= %@ AND periodEnd >= %@ AND isActive == YES",
                                  now as NSDate, now as NSDate)
        let query = CKQuery(recordType: "VendorPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "overallScore", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return VendorPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetch(byId id: CKRecord.ID) async throws -> VendorPerformance? {
        let record = try await database.record(for: id)
        return VendorPerformance(record: record)
    }
    
    func save(_ performance: VendorPerformance) async throws -> VendorPerformance {
        let record = performance.toRecord()
        let savedRecord = try await database.save(record)
        return VendorPerformance(record: savedRecord) ?? performance
    }
    
    func delete(_ performance: VendorPerformance) async throws {
        try await database.deleteRecord(withID: performance.id)
    }
    
    func fetchTopPerformers(limit: Int = 10) async throws -> [VendorPerformance] {
        let predicate = NSPredicate(format: "grade IN %@ AND isActive == YES", [
            VendorPerformance.PerformanceGrade.excellent.rawValue,
            VendorPerformance.PerformanceGrade.good.rawValue
        ])
        let query = CKQuery(recordType: "VendorPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "overallScore", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        let performers = results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return VendorPerformance(record: record)
            case .failure:
                return nil
            }
        }
        
        return Array(performers.prefix(limit))
    }
    
    func fetchUnderperformers() async throws -> [VendorPerformance] {
        let predicate = NSPredicate(format: "grade IN %@ AND isActive == YES", [
            VendorPerformance.PerformanceGrade.needsImprovement.rawValue,
            VendorPerformance.PerformanceGrade.poor.rawValue,
            VendorPerformance.PerformanceGrade.failing.rawValue
        ])
        let query = CKQuery(recordType: "VendorPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "overallScore", ascending: true)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return VendorPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
}

// MARK: - CategoryPerformance Repository Protocol
protocol CategoryPerformanceRepositoryProtocol {
    func fetchAll() async throws -> [CategoryPerformance]
    func fetchByCategory(_ categoryId: String) async throws -> [CategoryPerformance]
    func fetchByStore(_ storeCode: String) async throws -> [CategoryPerformance]
    func fetchByPeriod(_ period: CategoryPerformance.ReportingPeriod, year: Int) async throws -> [CategoryPerformance]
    func fetchCurrentPeriod() async throws -> [CategoryPerformance]
    func fetchTopPerformingCategories(limit: Int) async throws -> [CategoryPerformance]
    func fetchUnderperformingCategories() async throws -> [CategoryPerformance]
    func fetch(byId id: CKRecord.ID) async throws -> CategoryPerformance?
    func save(_ performance: CategoryPerformance) async throws -> CategoryPerformance
    func delete(_ performance: CategoryPerformance) async throws
}

// MARK: - CloudKit CategoryPerformance Repository
class CloudKitCategoryPerformanceRepository: CategoryPerformanceRepositoryProtocol {
    private let database: CKDatabase
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchAll() async throws -> [CategoryPerformance] {
        let query = CKQuery(recordType: "CategoryPerformance", predicate: NSPredicate(format: "isActive == YES"))
        query.sortDescriptors = [NSSortDescriptor(key: "periodStart", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return CategoryPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByCategory(_ categoryId: String) async throws -> [CategoryPerformance] {
        let predicate = NSPredicate(format: "categoryId == %@ AND isActive == YES", categoryId)
        let query = CKQuery(recordType: "CategoryPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "periodStart", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return CategoryPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByStore(_ storeCode: String) async throws -> [CategoryPerformance] {
        let predicate = NSPredicate(format: "storeCode == %@ AND isActive == YES", storeCode)
        let query = CKQuery(recordType: "CategoryPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "categoryName", ascending: true)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return CategoryPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByPeriod(_ period: CategoryPerformance.ReportingPeriod, year: Int) async throws -> [CategoryPerformance] {
        let startOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = Calendar.current.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        
        let predicate = NSPredicate(format: "reportingPeriod == %@ AND periodStart >= %@ AND periodStart < %@ AND isActive == YES",
                                  period.rawValue, startOfYear as NSDate, endOfYear as NSDate)
        let query = CKQuery(recordType: "CategoryPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "performance.overallScore", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return CategoryPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchCurrentPeriod() async throws -> [CategoryPerformance] {
        let now = Date()
        let predicate = NSPredicate(format: "periodStart <= %@ AND periodEnd >= %@ AND isActive == YES",
                                  now as NSDate, now as NSDate)
        let query = CKQuery(recordType: "CategoryPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "performance.overallScore", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return CategoryPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchTopPerformingCategories(limit: Int = 10) async throws -> [CategoryPerformance] {
        let predicate = NSPredicate(format: "performance.categoryGrade IN %@ AND isActive == YES", [
            "excellent", "good"
        ])
        let query = CKQuery(recordType: "CategoryPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "performance.overallScore", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        let performers = results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return CategoryPerformance(record: record)
            case .failure:
                return nil
            }
        }
        
        return Array(performers.prefix(limit))
    }
    
    func fetchUnderperformingCategories() async throws -> [CategoryPerformance] {
        let predicate = NSPredicate(format: "performance.categoryGrade IN %@ AND isActive == YES", [
            "needs_improvement", "poor"
        ])
        let query = CKQuery(recordType: "CategoryPerformance", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "performance.overallScore", ascending: true)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return CategoryPerformance(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetch(byId id: CKRecord.ID) async throws -> CategoryPerformance? {
        let record = try await database.record(for: id)
        return CategoryPerformance(record: record)
    }
    
    func save(_ performance: CategoryPerformance) async throws -> CategoryPerformance {
        let record = performance.toRecord()
        let savedRecord = try await database.save(record)
        return CategoryPerformance(record: savedRecord) ?? performance
    }
    
    func delete(_ performance: CategoryPerformance) async throws {
        try await database.deleteRecord(withID: performance.id)
    }
}

// MARK: - SalesTarget Repository Protocol
protocol SalesTargetRepositoryProtocol {
    func fetchAll() async throws -> [SalesTarget]
    func fetchActive() async throws -> [SalesTarget]
    func fetchByStore(_ storeCode: String) async throws -> [SalesTarget]
    func fetchByEmployee(_ employeeRef: CKRecord.Reference) async throws -> [SalesTarget]
    func fetchByPeriod(_ period: SalesTarget.TargetPeriod, year: Int) async throws -> [SalesTarget]
    func fetchCurrentTargets() async throws -> [SalesTarget]
    func fetchOverdueTargets() async throws -> [SalesTarget]
    func fetch(byId id: CKRecord.ID) async throws -> SalesTarget?
    func save(_ target: SalesTarget) async throws -> SalesTarget
    func delete(_ target: SalesTarget) async throws
    func updateAchievement(_ target: SalesTarget, currentValue: Double) async throws -> SalesTarget
}

// MARK: - CloudKit SalesTarget Repository
class CloudKitSalesTargetRepository: SalesTargetRepositoryProtocol {
    private let database: CKDatabase
    
    init(database: CKDatabase = CKContainer.default().publicCloudDatabase) {
        self.database = database
    }
    
    func fetchAll() async throws -> [SalesTarget] {
        let query = CKQuery(recordType: "SalesTarget", predicate: NSPredicate(format: "isActive == YES"))
        query.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return SalesTarget(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchActive() async throws -> [SalesTarget] {
        let predicate = NSPredicate(format: "status == %@ AND isActive == YES", SalesTarget.TargetStatus.active.rawValue)
        let query = CKQuery(recordType: "SalesTarget", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: true)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return SalesTarget(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByStore(_ storeCode: String) async throws -> [SalesTarget] {
        let predicate = NSPredicate(format: "storeCode == %@ AND isActive == YES", storeCode)
        let query = CKQuery(recordType: "SalesTarget", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return SalesTarget(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByEmployee(_ employeeRef: CKRecord.Reference) async throws -> [SalesTarget] {
        let predicate = NSPredicate(format: "employeeRef == %@ AND isActive == YES", employeeRef)
        let query = CKQuery(recordType: "SalesTarget", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return SalesTarget(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchByPeriod(_ period: SalesTarget.TargetPeriod, year: Int) async throws -> [SalesTarget] {
        let predicate = NSPredicate(format: "period == %@ AND fiscalYear == %d AND isActive == YES", 
                                  period.rawValue, year)
        let query = CKQuery(recordType: "SalesTarget", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "achievements.achievementPercentage", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return SalesTarget(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchCurrentTargets() async throws -> [SalesTarget] {
        let now = Date()
        let predicate = NSPredicate(format: "startDate <= %@ AND endDate >= %@ AND status == %@ AND isActive == YES",
                                  now as NSDate, now as NSDate, SalesTarget.TargetStatus.active.rawValue)
        let query = CKQuery(recordType: "SalesTarget", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "achievements.achievementPercentage", ascending: false)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return SalesTarget(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetchOverdueTargets() async throws -> [SalesTarget] {
        let now = Date()
        let predicate = NSPredicate(format: "endDate < %@ AND status == %@ AND isActive == YES",
                                  now as NSDate, SalesTarget.TargetStatus.active.rawValue)
        let query = CKQuery(recordType: "SalesTarget", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: true)]
        
        let (results, _) = try await database.records(matching: query)
        return results.compactMap { (_, result) in
            switch result {
            case .success(let record):
                return SalesTarget(record: record)
            case .failure:
                return nil
            }
        }
    }
    
    func fetch(byId id: CKRecord.ID) async throws -> SalesTarget? {
        let record = try await database.record(for: id)
        return SalesTarget(record: record)
    }
    
    func save(_ target: SalesTarget) async throws -> SalesTarget {
        let record = target.toRecord()
        let savedRecord = try await database.save(record)
        return SalesTarget(record: savedRecord) ?? target
    }
    
    func delete(_ target: SalesTarget) async throws {
        try await database.deleteRecord(withID: target.id)
    }
    
    func updateAchievement(_ target: SalesTarget, currentValue: Double) async throws -> SalesTarget {
        // Calculate updated achievement metrics
        let primaryTarget = target.targets.primaryTarget.value
        let achievementPercentage = primaryTarget > 0 ? (currentValue / primaryTarget) * 100 : 0
        let variance = currentValue - primaryTarget
        let variancePercentage = primaryTarget > 0 ? (variance / primaryTarget) * 100 : 0
        
        // Determine achievement status
        let status: SalesTarget.AchievementMetrics.AchievementStatus
        if achievementPercentage >= 110 {
            status = .exceeded
        } else if achievementPercentage >= 100 {
            status = .completed
        } else if achievementPercentage >= 75 {
            status = .onTrack
        } else if achievementPercentage >= 50 {
            status = .behindTarget
        } else {
            status = .atRisk
        }
        
        // Calculate projected achievement
        let timeElapsed = Date().timeIntervalSince(target.startDate)
        let totalDuration = target.endDate.timeIntervalSince(target.startDate)
        let timeElapsedPercentage = min(max((timeElapsed / totalDuration) * 100, 0), 100)
        
        let runRate = timeElapsedPercentage > 0 ? (currentValue / timeElapsedPercentage) * 100 : 0
        let projectedAchievement = min(runRate, primaryTarget * 2) // Cap at 200%
        
        // Create updated achievement metrics
        let updatedAchievements = SalesTarget.AchievementMetrics(
            currentValue: currentValue,
            achievementPercentage: achievementPercentage,
            achievementStatus: status,
            runRate: runRate,
            projectedAchievement: projectedAchievement,
            varianceFromTarget: variance,
            variancePercentage: variancePercentage,
            timeElapsed: timeElapsedPercentage,
            timeRemaining: target.endDate.timeIntervalSince(Date()),
            requiredRunRate: primaryTarget > 0 ? (primaryTarget - currentValue) / max(target.endDate.timeIntervalSince(Date()) / 86400, 1) : 0,
            trend: .stable, // Would need historical data to calculate trend
            lastCalculated: Date()
        )
        
        // Create updated target with new achievements
        let updatedTarget = SalesTarget(
            id: target.id,
            targetName: target.targetName,
            targetType: target.targetType,
            targetLevel: target.targetLevel,
            targetScope: target.targetScope,
            storeCode: target.storeCode,
            storeName: target.storeName,
            employeeRef: target.employeeRef,
            employeeName: target.employeeName,
            categoryId: target.categoryId,
            categoryName: target.categoryName,
            productId: target.productId,
            productName: target.productName,
            period: target.period,
            startDate: target.startDate,
            endDate: target.endDate,
            fiscalYear: target.fiscalYear,
            fiscalQuarter: target.fiscalQuarter,
            fiscalMonth: target.fiscalMonth,
            targets: target.targets,
            achievements: updatedAchievements,
            performance: target.performance,
            tracking: target.tracking,
            incentives: target.incentives,
            adjustments: target.adjustments,
            milestones: target.milestones,
            alerts: target.alerts,
            notes: target.notes,
            status: target.status,
            isActive: target.isActive,
            createdBy: target.createdBy,
            createdByName: target.createdByName,
            approvedBy: target.approvedBy,
            approvedByName: target.approvedByName,
            approvedAt: target.approvedAt,
            lastReviewed: target.lastReviewed,
            reviewedBy: target.reviewedBy,
            reviewedByName: target.reviewedByName,
            createdAt: target.createdAt,
            updatedAt: Date()
        )
        
        return try await save(updatedTarget)
    }
}

// MARK: - Performance Repository Factory
class PerformanceRepositoryFactory {
    static func makeVendorPerformanceRepository() -> VendorPerformanceRepositoryProtocol {
        return CloudKitVendorPerformanceRepository()
    }
    
    static func makeCategoryPerformanceRepository() -> CategoryPerformanceRepositoryProtocol {
        return CloudKitCategoryPerformanceRepository()
    }
    
    static func makeSalesTargetRepository() -> SalesTargetRepositoryProtocol {
        return CloudKitSalesTargetRepository()
    }
}
