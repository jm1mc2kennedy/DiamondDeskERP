// KPIRepository.swift
// Diamond Desk ERP
// CRUD abstraction and implementation for CloudKit KPIRecord operations

import Foundation
import CloudKit

protocol KPIRepository {
    func fetchForStore(_ storeCode: String) async throws -> [KPIModel]
    func save(_ kpi: KPIModel) async throws
}

class CloudKitKPIRepository: KPIRepository {
    let db = CKContainer.default().publicCloudDatabase

    func fetchForStore(_ storeCode: String) async throws -> [KPIModel] {
        let pred = NSPredicate(format: "storeCode == %@", storeCode)
        let query = CKQuery(recordType: "KPIRecord", predicate: pred)
        let (results, _) = try await db.records(matching: query)
        return results.compactMap { KPIModel(record: $0) }
    }

    func save(_ kpi: KPIModel) async throws {
        let record = kpi.toRecord()
        _ = try await db.save(record)
    }
}
