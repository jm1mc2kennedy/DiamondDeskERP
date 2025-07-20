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

    /// Fetch all performance targets from CloudKit
    func fetchAllTargets() async throws -> [PerformanceTarget] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "PerformanceTarget", predicate: predicate)
        // Fetch matching records
        let (matchResults, _) = try await database.records(matching: query)
        var targets: [PerformanceTarget] = []
        for result in matchResults {
            switch result {
            case .success(_, let record):
                if let target = PerformanceTarget.fromCloudKitRecord(record) {
                    targets.append(target)
                }
            case .failure(let error, _):
                throw error
            }
        }
        return targets
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
