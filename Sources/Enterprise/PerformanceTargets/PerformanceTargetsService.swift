//
//  PerformanceTargetsService.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit

@MainActor
class PerformanceTargetsService {
    static let shared = PerformanceTargetsService()
    private init() {}

    func fetchTargets() async throws -> [PerformanceTarget] {
        // TODO: Query CloudKit for PerformanceTarget records
        return []
    }

    func fetchTarget(by id: UUID) async throws -> PerformanceTarget? {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = try await CKContainer.default().privateCloudDatabase.record(for: recordID)
        return PerformanceTarget.fromCloudKitRecord(record)
    }

    func saveTarget(_ target: PerformanceTarget) async throws {
        let record = target.toCloudKitRecord()
        try await CKContainer.default().privateCloudDatabase.save(record)
    }

    func deleteTarget(_ target: PerformanceTarget) async throws {
        let recordID = CKRecord.ID(recordName: target.id.uuidString)
        try await CKContainer.default().privateCloudDatabase.deleteRecord(withID: recordID)
    }
}
