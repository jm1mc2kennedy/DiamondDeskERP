// StoreReportRepository.swift
// Diamond Desk ERP
// CRUD abstraction and implementation for CloudKit StoreReport operations

import Foundation
import CloudKit

protocol StoreReportRepository {
    func fetchForStore(_ storeCode: String, in range: ClosedRange<Date>?) async throws -> [StoreReportModel]
    func save(_ report: StoreReportModel) async throws
}

class CloudKitStoreReportRepository: StoreReportRepository {
    let db = CKContainer.default().publicCloudDatabase
    
    func fetchForStore(_ storeCode: String, in range: ClosedRange<Date>? = nil) async throws -> [StoreReportModel] {
        var predicate = NSPredicate(format: "storeCode == %@", storeCode)
        if let range = range {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "storeCode == %@", storeCode),
                NSPredicate(format: "date >= %@ AND date <= %@", range.lowerBound as NSDate, range.upperBound as NSDate)
            ])
        }
        let query = CKQuery(recordType: "StoreReport", predicate: predicate)
        let (results, _) = try await db.records(matching: query)
        return results.compactMap { StoreReportModel(record: $0) }
    }
    
    func save(_ report: StoreReportModel) async throws {
        let record = report.toRecord()
        _ = try await db.save(record)
    }
}
