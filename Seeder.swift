// Seeder.swift
// Seeds initial CloudKit schema-critical records (PerformanceGoal, Stores) for Diamond Desk ERP
// Reference: AppProjectBuildoutPlanVS2.md Appendix H, A

import Foundation
import CloudKit

struct Seeder {
    static func runIfNeeded() async throws {
        if try await needsGlobalGoal() { try await seedGlobalGoal() }
        if try await storesMissing() { try await seedStores() }
    }

    // MARK: - PerformanceGoal
    private static func needsGlobalGoal() async throws -> Bool {
        let currentMonth = DateFormatter.yearMonth.string(from: Date())
        let pred = NSPredicate(format: "period == %@ AND scope == %@", currentMonth, "global")
        let query = CKQuery(recordType: "PerformanceGoal", predicate: pred)
        let db = CKContainer.default().publicCloudDatabase
        let (results, _) = try await db.records(matching: query)
        return results.isEmpty
    }
    private static func seedGlobalGoal() async throws {
        let currentMonth = DateFormatter.yearMonth.string(from: Date())
        let rec = CKRecord(recordType: "PerformanceGoal")
        rec["period"] = currentMonth as CKRecordValue
        rec["scope"] = "global" as CKRecordValue
        // Encode targets as JSON Data, since CKRecord does not support NSDictionary directly
        let targets: [String: Any] = [
            "salesTarget": 100_000,
            "upt": 3.5,
            "ads": 120.0
        ]
        let targetsData = try JSONSerialization.data(withJSONObject: targets, options: [])
        rec["targets"] = targetsData as CKRecordValue
        rec["createdAt"] = Date() as CKRecordValue
        rec["createdByRef"] = nil // Set to admin/user id if available
        let db = CKContainer.default().publicCloudDatabase
        _ = try await db.save(rec)
        print("Seeded global PerformanceGoal for \(currentMonth)")
    }
    
    // MARK: - Stores
    private static func storesMissing() async throws -> Bool {
        let query = CKQuery(recordType: "Store", predicate: NSPredicate(value: true))
        let db = CKContainer.default().publicCloudDatabase
        let (results, _) = try await db.records(matching: query)
        return results.isEmpty
    }
    private static func seedStores() async throws {
        guard let url = Bundle.main.url(forResource: "SeedStores", withExtension: "json") else { throw SeederError.missingSeedFile }
        let data = try Data(contentsOf: url)
        let stores = try JSONDecoder().decode([StoreSeed].self, from: data)
        let db = CKContainer.default().publicCloudDatabase
        for store in stores {
            let rec = CKRecord(recordType: "Store")
            rec["code"] = store.code as CKRecordValue
            rec["name"] = store.name as CKRecordValue
            rec["status"] = store.status as CKRecordValue
            rec["region"] = store.region as CKRecordValue
            rec["createdAt"] = Date() as CKRecordValue
            _ = try await db.save(rec)
        }
        print("Seeded \(stores.count) stores to CloudKit.")
    }
    
    struct StoreSeed: Codable {
        let code: String
        let name: String
        let status: String
        let region: String
    }
    
    enum SeederError: Error {
        case missingSeedFile
    }
}

extension DateFormatter {
    static let yearMonth: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        return df
    }()
}
