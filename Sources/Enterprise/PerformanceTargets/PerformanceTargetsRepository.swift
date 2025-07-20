//
//  PerformanceTargetsRepository.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import Foundation
import CloudKit

class PerformanceTargetsRepository {
    private let database = CKContainer.default().privateCloudDatabase

    func fetchAllTargets() async throws -> [PerformanceTarget] {
        // TODO: Build CKQuery to fetch all PerformanceTarget records
        return []
    }

    func fetchTargetRecord(id: CKRecord.ID) async throws -> PerformanceTarget? {
        let record = try await database.record(for: id)
        return PerformanceTarget.fromCloudKitRecord(record)
    }

    func saveTargetRecord(_ target: PerformanceTarget) async throws {
        let record = target.toCloudKitRecord()
        try await database.save(record)
    }

    func deleteTargetRecord(id: CKRecord.ID) async throws {
        try await database.deleteRecord(withID: id)
    }
}
