// TaskRepository.swift
// Diamond Desk ERP
// CRUD abstraction and implementation for CloudKit Task operations

import Foundation
import CloudKit

protocol TaskRepository {
    func fetchAssigned(to userRef: String) async throws -> [TaskModel]
    func save(_ task: TaskModel) async throws
}

class CloudKitTaskRepository: TaskRepository {
    let db = CKContainer.default().publicCloudDatabase

    func fetchAssigned(to userRef: String) async throws -> [TaskModel] {
        let pred = NSPredicate(format: "assignedUserRefs CONTAINS %@", userRef)
        let query = CKQuery(recordType: "Task", predicate: pred)
        let (results, _) = try await db.records(matching: query)
        return results.compactMap { TaskModel(record: $0) }
    }

    func save(_ task: TaskModel) async throws {
        let record = task.toRecord()
        _ = try await db.save(record)
    }
}
